import XCTest

/// Design-review captures: every screen in light, dark and extra-large text, to compare
/// side by side with the artboards in Design/reference. Exported by CI to Design/review.
@MainActor
final class ReviewScreenshotTests: XCTestCase {
    private struct Variant {
        let name: String
        let arguments: [String]
    }

    private let variants = [
        Variant(name: "light", arguments: []),
        Variant(name: "dark", arguments: ["-StillDemoDark"]),
        Variant(name: "xxl", arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXL"]),
    ]

    /// (file name, launch arguments, element to wait for)
    private let screens: [(String, [String], String?)] = [
        ("01-onboarding", [], "allowScreenTime"),
        ("02-home", ["-StillDemoSkipOnboarding", "-StillDemoHistory"], "bigCircle"),
        ("03-choose-apps", ["-StillDemoSkipOnboarding", "-StillDemoScreen", "chooseApps"], "chooseAppsButton"),
        ("04-session", ["-StillDemoSkipOnboarding", "-StillDemoScreen", "session"], "holdToEnd"),
        ("05-shield", ["-StillDemoSkipOnboarding", "-StillDemoScreen", "shield"], nil),
        ("06-paywall", ["-StillDemoSkipOnboarding", "-StillDemoScreen", "paywall"], nil),
        ("07-complete", ["-StillDemoSkipOnboarding", "-StillDemoHistory", "-StillDemoScreen", "complete"], "completeDone"),
        ("08-ended-early", ["-StillDemoSkipOnboarding", "-StillDemoScreen", "endedEarly"], "endedEarlyOK"),
        ("09-custom-duration", ["-StillDemoSkipOnboarding", "-StillDemoPro", "-StillDemoScreen", "customDuration"], "setDuration"),
        ("10-settings", ["-StillDemoSkipOnboarding", "-StillDemoPro", "-StillDemoScreen", "settings"], "schedulesRow"),
        ("11-no-access", ["-StillDemoSkipOnboarding", "-StillDemoScreen", "noAccess"], "openSettings"),
        ("12-live-activity", ["-StillDemoSkipOnboarding", "-StillDemoScreen", "liveActivity"], nil),
        ("13-schedules", ["-StillDemoSkipOnboarding", "-StillDemoPro", "-StillDemoScreen", "schedules"], "addSchedule"),
        ("14-insights", ["-StillDemoSkipOnboarding", "-StillDemoPro", "-StillDemoHistory", "-StillDemoScreen", "insights"], nil),
    ]

    func testCaptureAllScreens() {
        continueAfterFailure = true
        for variant in variants {
            for (name, arguments, waitFor) in screens {
                let app = XCUIApplication()
                app.launchArguments = ["-StillDemo"] + arguments + variant.arguments
                app.launch()
                if let waitFor {
                    _ = app.descendants(matching: .any)[waitFor].waitForExistence(timeout: 10)
                }
                Thread.sleep(forTimeInterval: name == "06-paywall" ? 4 : 1.5)
                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "\(variant.name)-\(name)"
                attachment.lifetime = .keepAlways
                add(attachment)
                app.terminate()
            }
        }
    }
}
