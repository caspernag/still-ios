import Foundation

public enum SessionError: Error, Equatable, Sendable {
    /// The requested duration is shorter than DeviceActivity allows.
    case tooShort(minimumMinutes: Int)
    /// The requested duration is longer than Still allows.
    case tooLong(maximumMinutes: Int)
    /// A session is already running.
    case alreadyRunning
    /// No apps, categories or websites are selected.
    case nothingSelected
}

/// Pure functions for session timing.
public enum SessionMath {
    /// Validates a duration in minutes against the 15 min ... 12 h range.
    public static func validate(minutes: Int) throws(SessionError) {
        if minutes < StillConstants.minimumSessionMinutes {
            throw .tooShort(minimumMinutes: StillConstants.minimumSessionMinutes)
        }
        if minutes > StillConstants.maximumSessionMinutes {
            throw .tooLong(maximumMinutes: StillConstants.maximumSessionMinutes)
        }
    }

    /// Clamps a duration in minutes into the allowed range.
    public static func clamp(minutes: Int) -> Int {
        min(max(minutes, StillConstants.minimumSessionMinutes), StillConstants.maximumSessionMinutes)
    }

    /// Creates a session starting at `start` that lasts `minutes`.
    public static func makeSession(
        start: Date,
        minutes: Int,
        isStrict: Bool,
        id: UUID = UUID()
    ) throws(SessionError) -> Session {
        try validate(minutes: minutes)
        let end = start.addingTimeInterval(TimeInterval(minutes * 60))
        return Session(id: id, start: start, end: end, isStrict: isStrict)
    }

    /// Seconds left until the session ends (never negative).
    public static func remaining(_ session: Session, now: Date) -> TimeInterval {
        max(0, session.end.timeIntervalSince(now))
    }

    /// Seconds elapsed since the session started, capped at the planned duration.
    public static func elapsed(_ session: Session, now: Date) -> TimeInterval {
        min(max(0, now.timeIntervalSince(session.start)), session.plannedDuration)
    }

    /// Fraction of the session that has passed, 0...1.
    public static func progress(_ session: Session, now: Date) -> Double {
        guard session.plannedDuration > 0 else { return 1 }
        return elapsed(session, now: now) / session.plannedDuration
    }

    /// Fraction of the session that is left, 1...0 (what the ring draws).
    public static func remainingFraction(_ session: Session, now: Date) -> Double {
        1 - progress(session, now: now)
    }

    public static func isExpired(_ session: Session, now: Date) -> Bool {
        now >= session.end
    }

    /// Splits minutes into hours and minutes, e.g. 105 -> (1, 45).
    public static func hoursAndMinutes(_ totalMinutes: Int) -> (hours: Int, minutes: Int) {
        let total = max(0, totalMinutes)
        return (total / 60, total % 60)
    }
}
