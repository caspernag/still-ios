import Foundation

/// Reclaimed time for one calendar day.
public struct DayTotal: Hashable, Sendable, Identifiable {
    public var day: Date
    public var seconds: TimeInterval
    public var sessions: Int
    public var id: Date { day }

    public var minutes: Int { Int(seconds / 60) }
}

/// Streaks, totals and insights computed from the session history.
///
/// Every function takes the `Calendar` to bucket days in, so results follow the
/// user's current time zone and first weekday.
public enum Stats {
    /// The calendar day a record belongs to: the day it started.
    public static func day(of record: SessionRecord, calendar: Calendar) -> Date {
        calendar.startOfDay(for: record.start)
    }

    /// Consecutive calendar days (ending today, or yesterday if nothing has been
    /// done yet today) with at least one session that counts toward the streak.
    public static func streak(records: [SessionRecord], now: Date, calendar: Calendar) -> Int {
        let days = Set(records.filter(\.countsTowardStreak).map { day(of: $0, calendar: calendar) })
        guard !days.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        var cursor: Date
        if days.contains(today) {
            cursor = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = calendar.startOfDay(for: previous)
        }
        return count
    }

    /// Total reclaimed seconds of the records that started inside `interval`.
    public static func reclaimedSeconds(records: [SessionRecord], in interval: DateInterval) -> TimeInterval {
        records
            .filter { interval.contains($0.start) && $0.start < interval.end }
            .reduce(0) { $0 + $1.reclaimedSeconds }
    }

    /// Total reclaimed seconds over all records.
    public static func reclaimedSeconds(records: [SessionRecord]) -> TimeInterval {
        records.reduce(0) { $0 + $1.reclaimedSeconds }
    }

    /// The calendar week containing `now` (respects the calendar's first weekday).
    public static func week(containing now: Date, calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: now)
            ?? DateInterval(start: calendar.startOfDay(for: now), duration: 7 * 86_400)
    }

    /// Reclaimed seconds in the calendar week containing `now`.
    public static func thisWeekSeconds(records: [SessionRecord], now: Date, calendar: Calendar) -> TimeInterval {
        reclaimedSeconds(records: records, in: week(containing: now, calendar: calendar))
    }

    /// Reclaimed time per day for the last `days` days, oldest first, ending today.
    public static func dailyTotals(
        records: [SessionRecord],
        days: Int = 7,
        now: Date,
        calendar: Calendar
    ) -> [DayTotal] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { offset -> DayTotal? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let start = calendar.startOfDay(for: day)
            let matching = records.filter { calendar.isDate($0.start, inSameDayAs: start) }
            return DayTotal(
                day: start,
                seconds: matching.reduce(0) { $0 + $1.reclaimedSeconds },
                sessions: matching.count
            )
        }
    }

    /// The interval covering the last `days` days, ending at the end of today.
    public static func lastDays(_ days: Int, now: Date, calendar: Calendar) -> DateInterval {
        let today = calendar.startOfDay(for: now)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? now
        return DateInterval(start: start, end: end)
    }

    /// Number of urge events inside `interval`.
    public static func urges(events: [Date], in interval: DateInterval) -> Int {
        events.filter { interval.contains($0) }.count
    }

    /// Number of finished sessions that started inside `interval`.
    public static func sessionCount(records: [SessionRecord], in interval: DateInterval) -> Int {
        records.filter { interval.contains($0.start) }.count
    }
}
