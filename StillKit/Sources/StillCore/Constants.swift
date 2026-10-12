import Foundation

/// App-wide constants shared by the app and all extensions.
public enum StillConstants {
    /// App Group shared by the app and every extension.
    public static let appGroup = "group.com.nagsoftware.still"

    /// DeviceActivity rejects intervals shorter than 15 minutes.
    public static let minimumSessionMinutes = 15
    /// The longest session the custom duration picker allows (12 hours).
    public static let maximumSessionMinutes = 12 * 60
    /// Preset durations offered on Home, in minutes.
    public static let presetMinutes = [15, 30, 60, 120]
    /// Default selected preset (30 minutes, as in the design).
    public static let defaultDurationMinutes = 30
    /// An early end of at least this many minutes still counts toward the streak.
    public static let earlyEndStreakMinimumMinutes = 10
    /// How long the "Hold to end early" button must be held.
    public static let holdToEndSeconds: Double = 5
    /// The review prompt is requested once, after this many completed sessions.
    public static let reviewPromptAfterCompletedSessions = 3
    /// DeviceActivityCenter allows at most 20 monitored activities per app.
    /// One slot is always kept free for a manual session.
    public static let maximumMonitoredActivities = 20

    public static let supportEmail = "casper@nagsoftware.no"
    public static let privacyURL = URL(string: "https://nagsoftware.no/still/privacy")!
    public static let termsURL = URL(string: "https://nagsoftware.no/still/terms")!
    public static let appleEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    public enum Products {
        public static let yearly = "com.nagsoftware.still.pro.yearly"
        public static let monthly = "com.nagsoftware.still.pro.monthly"
        public static let all = [yearly, monthly]
    }
}
