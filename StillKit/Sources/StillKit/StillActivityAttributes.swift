#if os(iOS)
import ActivityKit
import Foundation

/// The Live Activity shown on the Lock Screen and in the Dynamic Island during a session.
///
/// The countdown is rendered with `Text(timerInterval:)` from `start` and `end`,
/// so the activity never needs updates while it runs.
public struct StillActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var start: Date
        public var end: Date
        /// Set when the session finished; the views then show "Session complete".
        public var isComplete: Bool

        public init(start: Date, end: Date, isComplete: Bool = false) {
            self.start = start
            self.end = end
            self.isComplete = isComplete
        }
    }

    public var sessionID: UUID
    /// The localized "3 categories locked" line, built by the app when the session starts.
    public var lockedSummary: String

    public init(sessionID: UUID, lockedSummary: String) {
        self.sessionID = sessionID
        self.lockedSummary = lockedSummary
    }
}
#endif
