import Foundation
import Observation
import StillKit
import StoreKit

/// Still Pro entitlement. Checks `Transaction.currentEntitlements` at launch, listens to
/// `Transaction.updates`, and gates every Pro feature through `canUse(_:)`.
@Observable
@MainActor
final class Entitlements {
    private(set) var status: ProStatus = .free
    /// False until the first entitlement check has finished.
    private(set) var isLoaded = false

    private let forcedStatus: ProStatus?
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(forcedStatus: ProStatus? = nil) {
        self.forcedStatus = forcedStatus
        if let forcedStatus {
            status = forcedStatus
            isLoaded = true
        }
    }

    var isPro: Bool { status.isPro }

    func canUse(_ feature: ProFeature) -> Bool {
        ProAccess.canUse(feature, status: status)
    }

    func start() {
        guard forcedStatus == nil, updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await self?.refresh()
            }
        }
        Task { await refresh() }
    }

    func refresh() async {
        guard forcedStatus == nil else { return }
        let now = Date()
        var best: ProStatus = .free

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  StillConstants.Products.all.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }
            if let expiration = transaction.expirationDate, expiration < now { continue }

            if Self.isIntroductoryOffer(transaction), let expiration = transaction.expirationDate {
                if best != .active {
                    best = .trial(daysLeft: ProStatus.trialDaysLeft(expiration: expiration, now: now))
                }
            } else {
                best = .active
            }
        }
        status = best
        isLoaded = true
    }

    private static func isIntroductoryOffer(_ transaction: Transaction) -> Bool {
        if #available(iOS 17.2, *) {
            return transaction.offer?.type == .introductory
        } else {
            return transaction.offerType == .introductory
        }
    }
}
