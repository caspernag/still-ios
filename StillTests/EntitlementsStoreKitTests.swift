import StoreKit
import StoreKitTest
import StillKit
import XCTest
@testable import Still

/// Purchases against Still.storekit (local StoreKit testing) and checks that Pro unlocks.
@MainActor
final class EntitlementsStoreKitTests: XCTestCase {
    private func makeSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "Still")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    func testProductsLoadWithFreeTrial() async throws {
        _ = try makeSession()
        let products = try await Product.products(for: StillConstants.Products.all)
        XCTAssertEqual(Set(products.map(\.id)), Set(StillConstants.Products.all))
        for product in products {
            let offer = try XCTUnwrap(product.subscription?.introductoryOffer)
            XCTAssertEqual(offer.paymentMode, .freeTrial)
            XCTAssertEqual(offer.period.unit, .week)
        }
    }

    func testFreeBeforePurchase() async throws {
        _ = try makeSession()
        let entitlements = Entitlements()
        await entitlements.refresh()
        XCTAssertEqual(entitlements.status, .free)
        XCTAssertFalse(entitlements.canUse(.schedules))
    }

    func testPurchaseStartsTrialAndUnlocksPro() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }
        let entitlements = Entitlements()
        _ = try await session.buyProduct(identifier: StillConstants.Products.yearly)
        await entitlements.refresh()

        XCTAssertTrue(entitlements.isPro)
        if case .trial(let days) = entitlements.status {
            XCTAssertEqual(days, 7)
        } else {
            XCTFail("Expected the 7-day trial, got \(entitlements.status)")
        }
        for feature in ProFeature.allCases {
            XCTAssertTrue(entitlements.canUse(feature))
        }
    }

    func testExpiredSubscriptionLocksPro() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }
        let entitlements = Entitlements()
        _ = try await session.buyProduct(identifier: StillConstants.Products.monthly)
        try session.expireSubscription(productIdentifier: StillConstants.Products.monthly)
        await entitlements.refresh()
        XCTAssertFalse(entitlements.isPro)
    }
}
