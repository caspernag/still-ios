import StillKit
import XCTest
@testable import Still

/// App-level tests in demo mode (fake Screen Time, isolated store).
@MainActor
final class AppModelTests: XCTestCase {
    private func makeModel(pro: Bool = false, skipOnboarding: Bool = true) -> AppModel {
        AppModel(config: LaunchConfiguration(isDemo: true, skipOnboarding: skipOnboarding, forcePro: pro))
    }

    private func demoScreenTime(_ model: AppModel) -> DemoScreenTimeService {
        model.screenTime as! DemoScreenTimeService
    }

    // MARK: Entitlement gating

    func testFreeUserSeesPaywallForEveryProFeature() {
        let model = makeModel(pro: false)

        model.tapCustomDuration()
        XCTAssertEqual(model.sheet, .paywall)
        model.sheet = nil

        model.openSchedules()
        XCTAssertEqual(model.sheet, .paywall)
        XCTAssertFalse(model.path.contains(.schedules))
        model.sheet = nil

        model.openInsights()
        XCTAssertEqual(model.sheet, .paywall)
        XCTAssertFalse(model.path.contains(.insights))
        model.sheet = nil

        model.setStrictMode(true)
        XCTAssertEqual(model.sheet, .paywall)
        XCTAssertFalse(model.settings.isStrictMode)
        XCTAssertFalse(model.isStrictModeEffective)
    }

    func testProUserCanUseEveryProFeature() {
        let model = makeModel(pro: true)

        model.tapCustomDuration()
        XCTAssertEqual(model.sheet, .customDuration)
        model.setCustomDuration(105)
        XCTAssertEqual(model.effectiveDurationMinutes, 105)
        XCTAssertNil(model.sheet)

        model.openSchedules()
        XCTAssertEqual(model.path.last, .schedules)
        model.openInsights()
        XCTAssertEqual(model.path.last, .insights)

        model.setStrictMode(true)
        XCTAssertTrue(model.isStrictModeEffective)
    }

    func testCustomDurationFallsBackWhenNotPro() {
        let model = makeModel(pro: false)
        model.setCustomDuration(45) // e.g. saved while Pro was active
        XCTAssertEqual(model.effectiveDurationMinutes, StillConstants.defaultDurationMinutes)
    }

    func testCustomDurationIsClampedToFifteenMinutes() {
        let model = makeModel(pro: true)
        model.setCustomDuration(5)
        XCTAssertEqual(model.effectiveDurationMinutes, 15)
        model.setCustomDuration(10_000)
        XCTAssertEqual(model.effectiveDurationMinutes, 720)
    }

    // MARK: Sessions

    func testStartWithoutSelectionOpensChooseApps() {
        let model = makeModel(skipOnboarding: false)
        model.startSession()
        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.path.last, .chooseApps)
    }

    func testStartAndEndEarly() throws {
        let model = makeModel()
        model.selectPreset(30)
        model.startSession()
        let session = try XCTUnwrap(model.activeSession)
        XCTAssertEqual(session.plannedMinutes, 30)
        XCTAssertTrue(demoScreenTime(model).sessionShieldActive)
        XCTAssertTrue(demoScreenTime(model).monitoredSessions.contains(session.id))

        model.endSessionEarly()
        XCTAssertNil(model.activeSession)
        XCTAssertFalse(demoScreenTime(model).sessionShieldActive)
        XCTAssertFalse(demoScreenTime(model).monitoredSessions.contains(session.id))
        XCTAssertEqual(model.endedEarly?.outcome, .endedEarly)
        XCTAssertNil(model.completion)
    }

    func testStrictSessionCannotEndEarly() {
        let model = makeModel(pro: true)
        model.setStrictMode(true)
        model.startSession()
        XCTAssertEqual(model.activeSession?.isStrict, true)
        model.endSessionEarly()
        XCTAssertNotNil(model.activeSession)
        XCTAssertTrue(demoScreenTime(model).sessionShieldActive)
    }

    func testReconcileFinalizesExpiredSession() throws {
        let model = makeModel()
        model.startSession()
        let session = try XCTUnwrap(model.activeSession)

        model.clock.advance(by: session.plannedDuration + 60)
        model.reconcile()

        XCTAssertNil(model.activeSession)
        XCTAssertEqual(model.completion?.id, session.id)
        XCTAssertEqual(model.completion?.outcome, .completed)
        XCTAssertFalse(demoScreenTime(model).sessionShieldActive)
        XCTAssertEqual(model.flags.completedSessionCount, 1)
    }

    func testPaywallShowsOnceAfterFirstCompletion() throws {
        let model = makeModel(pro: false)

        model.startSession()
        model.fastForward()
        XCTAssertNotNil(model.completion)
        model.dismissCompletion(goAgain: false)
        model.completionDismissed()
        XCTAssertEqual(model.sheet, .paywall)
        XCTAssertTrue(model.flags.hasSeenAutomaticPaywall)
        model.sheet = nil

        model.startSession()
        model.fastForward()
        model.dismissCompletion(goAgain: false)
        model.completionDismissed()
        XCTAssertNil(model.sheet)
    }

    func testNoAutomaticPaywallForPro() {
        let model = makeModel(pro: true)
        model.startSession()
        model.fastForward()
        model.dismissCompletion(goAgain: false)
        model.completionDismissed()
        XCTAssertNil(model.sheet)
    }

    func testReviewRequestedOnceAfterThirdCompletion() {
        let model = makeModel(pro: true)
        var requests: [Bool] = []
        for _ in 0..<4 {
            model.startSession()
            model.fastForward()
            requests.append(model.completionAppeared())
            model.dismissCompletion(goAgain: false)
            model.completionDismissed()
        }
        XCTAssertEqual(requests, [false, false, true, false])
    }

    // MARK: Schedules

    func testSeededNightsScheduleIsOff() {
        let model = makeModel(pro: true)
        XCTAssertEqual(model.schedules.count, 1)
        XCTAssertFalse(model.schedules[0].isEnabled)
        XCTAssertEqual(model.schedules[0].start, TimeOfDay(hour: 22, minute: 0))
        XCTAssertEqual(model.schedules[0].end, TimeOfDay(hour: 7, minute: 0))
    }

    func testSchedulesAreRegisteredOnlyForPro() {
        let free = makeModel(pro: false)
        free.setSchedule(free.schedules[0].id, enabled: true)
        XCTAssertTrue(demoScreenTime(free).registeredSchedules.allSatisfy { !$0.isEnabled })

        let pro = makeModel(pro: true)
        pro.setSchedule(pro.schedules[0].id, enabled: true)
        XCTAssertEqual(demoScreenTime(pro).registeredSchedules.filter(\.isEnabled).count, 1)
    }

    func testTooManySchedulesAreRejected() {
        let model = makeModel(pro: true)
        let sixDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        let many = (0..<4).map { index in
            StillSchedule(
                name: "S\(index)", start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 10, minute: 0),
                weekdays: sixDays, isEnabled: true
            )
        }
        let before = model.schedules
        XCTAssertFalse(model.saveSchedules(many))
        XCTAssertEqual(model.schedules, before)
        XCTAssertNotNil(model.errorMessage)
    }

    // MARK: Formatting

    func testDurationFormatting() {
        // The test host runs in English.
        guard Locale.current.language.languageCode == .english else { return }
        XCTAssertEqual(Formatters.longDuration(minutes: 30), "30 minutes")
        XCTAssertEqual(Formatters.longDuration(minutes: 60), "1 hour")
        XCTAssertEqual(Formatters.longDuration(minutes: 105), "1 h 45 min")
        XCTAssertEqual(Formatters.segmentTitle(minutes: 15), "15 min")
        XCTAssertEqual(Formatters.segmentTitle(minutes: 120), "2 hours")
        XCTAssertEqual(Formatters.duration(seconds: 192 * 60), "3 h 12 min")
        XCTAssertEqual(Formatters.blockingTitle(SelectionSummary(categories: 3)), "Blocking 3 categories")
        XCTAssertEqual(Formatters.lockedLabel(SelectionSummary(categories: 3)), "categories locked")
        XCTAssertEqual(Formatters.reclaimedStreakLine(streak: 6), "reclaimed · 6 day streak")
    }
}
