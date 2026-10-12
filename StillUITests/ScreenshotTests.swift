import XCTest

/// Captures App Store screenshots in demo mode. Run through `Scripts/screenshots.sh`,
/// which overrides the status bar and exports the attachments to AppStore/screenshots.
@MainActor
final class ScreenshotTests: XCTestCase {
    private func capture(_ name: String, arguments: [String], waitFor identifier: String? = nil) {
        let app = XCUIApplication()
        app.launchArguments = ["-StillDemo", "-StillDemoSkipOnboarding", "-StillDemoHistory"] + arguments
        app.launch()
        if let identifier {
            _ = app.descendants(matching: .any)[identifier].waitForExistence(timeout: 10)
        }
        // Let animations and StoreKit settle.
        Thread.sleep(forTimeInterval: 1.5)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        app.terminate()
    }

    func testScreenshots() {
        capture("01-Home", arguments: [], waitFor: "bigCircle")
        capture("02-Session", arguments: ["-StillDemoScreen", "session"], waitFor: "holdToEnd")
        capture("03-Shield", arguments: ["-StillDemoScreen", "shield"])
        capture("04-LiveActivity", arguments: ["-StillDemoScreen", "liveActivity"])
        capture("05-ChooseApps", arguments: ["-StillDemoScreen", "chooseApps"], waitFor: "chooseAppsButton")
        capture("06-Insights", arguments: ["-StillDemoPro", "-StillDemoScreen", "insights"])
    }
}
