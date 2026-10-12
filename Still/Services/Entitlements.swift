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
    /// Whether this Apple Account can still get the 7-day free trial.
    private(set) var isTrialEligible = true

    private let forcedStatus: ProStatus?
    private let store: SharedStore
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init(forcedStatus: ProStatus? = nil, store: SharedStore = .shared) {
        self.forcedStatus = forcedStatus
        self.store = store
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
        var activeUntil: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  StillConstants.Products.all.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }
            if let expiration = transaction.expirationDate, expiration < now { continue }
            activeUntil = max(activeUntil ?? .distantPast, transaction.expirationDate ?? .distantFuture)

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
        // Lets the monitor extension stop schedules after Pro lapses.
        store.proActiveUntil = activeUntil

        if let product = try? await Product.products(for: [StillConstants.Products.yearly]).first,
           let subscription = product.subscription {
            isTrialEligible = await subscription.isEligibleForIntroOffer
        }
    }

    private static func isIntroductoryOffer(_ transaction: Transaction) -> Bool {
        if #available(iOS 17.2, *) {
            return transaction.offer?.type == .introductory
        } else {
            return transaction.offerType == .introductory
        }
    }
}
