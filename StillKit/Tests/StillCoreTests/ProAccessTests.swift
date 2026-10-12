import XCTest
@testable import StillCore

final class ProAccessTests: XCTestCase {
    func testFreeUsersCannotUseProFeatures() {
        for feature in ProFeature.allCases {
            XCTAssertFalse(ProAccess.canUse(feature, status: .free), "\(feature)")
            XCTAssertFalse(ProAccess.canUse(feature, status: .expired), "\(feature)")
            XCTAssertTrue(ProAccess.canUse(feature, status: .trial(daysLeft: 3)), "\(feature)")
            XCTAssertTrue(ProAccess.canUse(feature, status: .active), "\(feature)")
        }
    }

    func testPresetsAreFreeAndCustomDurationsNeedPro() {
        for minutes in StillConstants.presetMinutes {
            XCTAssertFalse(ProAccess.requiresPro(durationMinutes: minutes))
        }
        XCTAssertTrue(ProAccess.requiresPro(durationMinutes: 45))
        XCTAssertTrue(ProAccess.requiresPro(durationMinutes: 105))
    }

    func testAutomaticPaywallShowsOnceAfterFirstCompletion() {
        var flags = StillFlags()
        XCTAssertFalse(ProAccess.shouldShowAutomaticPaywall(flags: flags, status: .free))
        flags.completedSessionCount = 1
        XCTAssertTrue(ProAccess.shouldShowAutomaticPaywall(flags: flags, status: .free))
        XCTAssertFalse(ProAccess.shouldShowAutomaticPaywall(flags: flags, status: .active))
        XCTAssertFalse(ProAccess.shouldShowAutomaticPaywall(flags: flags, status: .trial(daysLeft: 7)))
        flags.hasSeenAutomaticPaywall = true
        XCTAssertFalse(ProAccess.shouldShowAutomaticPaywall(flags: flags, status: .free))
        flags.completedSessionCount = 5
        XCTAssertFalse(ProAccess.shouldShowAutomaticPaywall(flags: flags, status: .free))
    }

    func testReviewIsRequestedOnceAfterThirdCompletion() {
        var flags = StillFlags()
        flags.completedSessionCount = 2
        XCTAssertFalse(ProAccess.shouldRequestReview(flags: flags))
        flags.completedSessionCount = 3
        XCTAssertTrue(ProAccess.shouldRequestReview(flags: flags))
        flags.hasRequestedReview = true
        XCTAssertFalse(ProAccess.shouldRequestReview(flags: flags))
    }

    func testTrialDaysLeftRoundsUp() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(ProStatus.trialDaysLeft(expiration: now.addingTimeInterval(7 * 86_400), now: now), 7)
        XCTAssertEqual(ProStatus.trialDaysLeft(expiration: now.addingTimeInterval(4.2 * 86_400), now: now), 5)
        XCTAssertEqual(ProStatus.trialDaysLeft(expiration: now.addingTimeInterval(60), now: now), 1)
        XCTAssertEqual(ProStatus.trialDaysLeft(expiration: now.addingTimeInterval(-60), now: now), 0)
    }

    func testStatusIsPro() {
        XCTAssertFalse(ProStatus.free.isPro)
        XCTAssertFalse(ProStatus.expired.isPro)
        XCTAssertTrue(ProStatus.active.isPro)
        XCTAssertTrue(ProStatus.trial(daysLeft: 1).isPro)
    }

    func testSettingsAndFlagsDefaults() {
        let store = makeStore()
        XCTAssertEqual(store.settings.durationMinutes, 30)
        XCTAssertTrue(store.settings.notifyWhenDone)
        XCTAssertFalse(store.settings.isStrictMode)
        XCTAssertFalse(store.flags.hasSeenAutomaticPaywall)
        XCTAssertEqual(store.flags.completedSessionCount, 0)

        var settings = store.settings
        settings.isStrictMode = true
        store.settings = settings
        XCTAssertTrue(store.settings.isStrictMode)
    }
}
