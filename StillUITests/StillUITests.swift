import XCTest

/// End-to-end flows in demo mode (`-StillDemo`): fake Screen Time authorization and
/// selection, so every screen is reachable in the simulator.
@MainActor
final class StillUITests: XCTestCase {
    private func launch(_ arguments: [String]) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-StillDemo"] + arguments
        app.launch()
        return app
    }

    private func paywallHeader(_ app: XCUIApplication) -> XCUIElement {
        app.staticTexts["Get your time back."]
    }

    /// onboarding → choose apps → home → start → session → hold to end → ended-early dialog
    func testOnboardingToEndedEarly() {
        let app = launch([])

        let allow = app.buttons["allowScreenTime"]
        XCTAssertTrue(allow.waitForExistence(timeout: 5))
        allow.tap()

        let choose = app.buttons["chooseAppsButton"]
        XCTAssertTrue(choose.waitForExistence(timeout: 5))
        choose.tap()
        app.buttons["doneButton"].tap()

        let start = app.buttons["startSession"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        let hold = app.buttons["holdToEnd"]
        XCTAssertTrue(hold.waitForExistence(timeout: 5))

        // A short press does nothing.
        hold.press(forDuration: 1)
        XCTAssertTrue(hold.exists)

        hold.press(forDuration: 5.6)
        let message = app.staticTexts["endedEarlyMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Session ended"].exists)

        app.buttons["endedEarlyOK"].tap()
        XCTAssertTrue(app.buttons["startSession"].waitForExistence(timeout: 5))
    }

    /// home → start → (fast-forward) → session complete → paywall shown once
    func testCompletionShowsPaywallOnlyOnce() {
        let app = launch(["-StillDemoSkipOnboarding"])

        app.buttons["startSession"].tap()
        app.buttons["demoFastForward"].tap()
        XCTAssertTrue(app.staticTexts["completeHeadline"].waitForExistence(timeout: 5))
        app.buttons["completeDone"].tap()

        XCTAssertTrue(paywallHeader(app).waitForExistence(timeout: 5))
        app.buttons["close"].firstMatch.tap()
        XCTAssertTrue(app.buttons["startSession"].waitForExistence(timeout: 5))

        // Second completion: no automatic paywall.
        app.buttons["startSession"].tap()
        app.buttons["demoFastForward"].tap()
        XCTAssertTrue(app.staticTexts["completeHeadline"].waitForExistence(timeout: 5))
        app.buttons["completeDone"].tap()
        XCTAssertTrue(app.buttons["startSession"].waitForExistence(timeout: 5))
        XCTAssertFalse(paywallHeader(app).waitForExistence(timeout: 2))
    }

    /// settings → schedules (paywall when free)
    func testSchedulesShowPaywallWhenFree() {
        let app = launch(["-StillDemoSkipOnboarding"])
        app.buttons["settingsButton"].tap()
        let schedules = app.buttons["schedulesRow"]
        XCTAssertTrue(schedules.waitForExistence(timeout: 5))
        schedules.tap()
        XCTAssertTrue(paywallHeader(app).waitForExistence(timeout: 5))
    }

    /// settings → schedules opens the list for Pro users.
    func testSchedulesOpenForPro() {
        let app = launch(["-StillDemoSkipOnboarding", "-StillDemoPro"])
        app.buttons["settingsButton"].tap()
        app.buttons["schedulesRow"].tap()
        XCTAssertTrue(app.buttons["addSchedule"].waitForExistence(timeout: 5))
        XCTAssertFalse(paywallHeader(app).exists)
    }

    /// The paywall renders the StoreKit test products (Still.storekit is selected in the scheme).
    func testPaywallRendersProducts() {
        let app = launch(["-StillDemoSkipOnboarding", "-StillDemoScreen", "paywall"])
        XCTAssertTrue(paywallHeader(app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Try Still Pro free for 7 days."].exists)

        let yearly = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Yearly")).firstMatch
        XCTAssertTrue(yearly.waitForExistence(timeout: 15), "StoreKit products did not load")
        let monthly = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Monthly")).firstMatch
        XCTAssertTrue(monthly.exists)
    }

    /// Free users get the paywall for a custom duration.
    func testCustomDurationIsPro() {
        let app = launch(["-StillDemoSkipOnboarding"])
        app.buttons["duration.custom"].tap()
        XCTAssertTrue(paywallHeader(app).waitForExistence(timeout: 5))
    }

    /// Pro users get the custom duration sheet.
    func testCustomDurationSheetForPro() {
        let app = launch(["-StillDemoSkipOnboarding", "-StillDemoPro"])
        app.buttons["duration.custom"].tap()
        XCTAssertTrue(app.buttons["setDuration"].waitForExistence(timeout: 5))
        app.buttons["setDuration"].tap()
        XCTAssertTrue(app.buttons["startSession"].waitForExistence(timeout: 5))
    }
}
