import Foundation

/// Locale-independent pieces used to build duration strings.
/// The app turns these into localized text through its String Catalog.
public enum DurationText {
    public enum Style: Equatable, Sendable {
        /// "45 min"
        case minutes(Int)
        /// "2 h"
        case hours(Int)
        /// "1 h 45 min"
        case hoursMinutes(Int, Int)
    }

    /// Splits a number of seconds into the style the design uses ("3 h 12 min").
    public static func style(seconds: TimeInterval) -> Style {
        style(minutes: Int(max(0, seconds) / 60))
    }

    public static func style(minutes: Int) -> Style {
        let (h, m) = SessionMath.hoursAndMinutes(minutes)
        if h == 0 { return .minutes(m) }
        if m == 0 { return .hours(h) }
        return .hoursMinutes(h, m)
    }
}
