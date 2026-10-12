import Foundation

/// A running (or just-finished) manual session, stored in the App Group.
public struct Session: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var start: Date
    public var end: Date
    public var isStrict: Bool

    public init(id: UUID = UUID(), start: Date, end: Date, isStrict: Bool) {
        self.id = id
        self.start = start
        self.end = end
        self.isStrict = isStrict
    }

    public var plannedDuration: TimeInterval { end.timeIntervalSince(start) }
    public var plannedMinutes: Int { Int((plannedDuration / 60).rounded()) }
    public var interval: ClosedRange<Date> { start...max(start, end) }
}

public enum SessionOutcome: String, Codable, Sendable {
    /// The timer ran out.
    case completed
    /// The user held the button to end the session early.
    case endedEarly
}

/// A finished session in the history.
public struct SessionRecord: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var start: Date
    public var plannedEnd: Date
    public var actualEnd: Date
    public var outcome: SessionOutcome
    public var urgesResisted: Int
    public var isStrict: Bool

    public init(
        id: UUID,
        start: Date,
        plannedEnd: Date,
        actualEnd: Date,
        outcome: SessionOutcome,
        urgesResisted: Int = 0,
        isStrict: Bool = false
    ) {
        self.id = id
        self.start = start
        self.plannedEnd = plannedEnd
        self.actualEnd = actualEnd
        self.outcome = outcome
        self.urgesResisted = urgesResisted
        self.isStrict = isStrict
    }

    /// Time actually spent "still": from start until the session ended,
    /// never more than planned and never negative.
    public var reclaimedSeconds: TimeInterval {
        let end = min(actualEnd, plannedEnd)
        return max(0, end.timeIntervalSince(start))
    }

    /// Whole minutes reclaimed in this session (partial minutes are rounded down).
    public var reclaimedMinutes: Int { Int(reclaimedSeconds / 60) }

    /// Completed sessions always count. An early end counts when it lasted
    /// at least `StillConstants.earlyEndStreakMinimumMinutes`.
    public var countsTowardStreak: Bool {
        switch outcome {
        case .completed:
            return true
        case .endedEarly:
            return reclaimedSeconds >= Double(StillConstants.earlyEndStreakMinimumMinutes * 60)
        }
    }
}
