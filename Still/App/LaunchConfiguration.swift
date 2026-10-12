import Foundation

/// How the app was launched.
///
/// Demo mode (`-StillDemo`) fakes Screen Time authorization and the app selection so
/// every screen can be reached in the simulator, in UI tests and for screenshots.
/// It only exists in DEBUG builds: in Release, `isDemo` is always false and the
/// launch arguments are never read.
struct LaunchConfiguration: Sendable {
    var isDemo = false
    /// Skip onboarding and start on Home with a demo selection.
    var skipOnboarding = false
    /// Pretend the user has Still Pro.
    var forcePro = false
    /// Seed a week of history (for screenshots).
    var seedHistory = false
    /// Open a specific screen directly (for screenshots).
    var initialScreen: DemoScreen?
    /// Force dark appearance (for design review screenshots).
    var forceDark = false

    enum DemoScreen: String, Sendable {
        case session
        case shield
        case liveActivity
        case chooseApps
        case insights
        case paywall
        case settings
        case schedules
        case complete
        case endedEarly
        case customDuration
        case noAccess
    }

    static let current: LaunchConfiguration = {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-StillDemo") else { return LaunchConfiguration() }
        var config = LaunchConfiguration(isDemo: true)
        config.skipOnboarding = arguments.contains("-StillDemoSkipOnboarding")
        config.forcePro = arguments.contains("-StillDemoPro")
        config.seedHistory = arguments.contains("-StillDemoHistory")
        config.forceDark = arguments.contains("-StillDemoDark")
        if let index = arguments.firstIndex(of: "-StillDemoScreen"), index + 1 < arguments.count {
            config.initialScreen = DemoScreen(rawValue: arguments[index + 1])
        }
        return config
        #else
        return LaunchConfiguration()
        #endif
    }()
}
