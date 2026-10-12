import Foundation

/// A day of the week, numbered like `Calendar.component(.weekday)` (Sunday = 1).
public enum Weekday: Int, Codable, CaseIterable, Comparable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    /// The following day (Saturday wraps to Sunday).
    public var next: Weekday { Weekday(rawValue: rawValue % 7 + 1)! }

    /// All weekdays ordered starting from the calendar's first weekday.
    public static func ordered(firstWeekday: Int) -> [Weekday] {
        (0..<7).map { Weekday(rawValue: (firstWeekday - 1 + $0) % 7 + 1)! }
    }
}

/// A wall-clock time, e.g. 22:00.
public struct TimeOfDay: Codable, Hashable, Comparable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public var minutesSinceMidnight: Int { hour * 60 + minute }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minutesSinceMidnight < rhs.minutesSinceMidnight
    }

    /// "22:00" style, zero padded. Used for stable identifiers; the UI formats with the locale.
    public var hhmm: String { String(format: "%02d:%02d", hour, minute) }
}

/// A recurring automatic lock (Pro).
public struct StillSchedule: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var start: TimeOfDay
    public var end: TimeOfDay
    public var weekdays: Set<Weekday>
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        start: TimeOfDay,
        end: TimeOfDay,
        weekdays: Set<Weekday>,
        isEnabled: Bool
    ) {
        self.id = id
        self.name = name
        self.start = start
        self.end = end
        self.weekdays = weekdays
        self.isEnabled = isEnabled
    }

    /// True when the schedule ends the next day, e.g. 22:00–07:00.
    public var crossesMidnight: Bool { end <= start }

    /// Length of one occurrence in minutes.
    public var durationMinutes: Int {
        let diff = end.minutesSinceMidnight - start.minutesSinceMidnight
        return diff > 0 ? diff : diff + 24 * 60
    }

    /// The example schedule seeded on first launch: "Nights 22:00–07:00", turned off.
    public static func nightsExample(name: String = "Nights") -> StillSchedule {
        StillSchedule(
            name: name,
            start: TimeOfDay(hour: 22, minute: 0),
            end: TimeOfDay(hour: 7, minute: 0),
            weekdays: Set(Weekday.allCases),
            isEnabled: false
        )
    }

    /// Whether `date` falls inside one of this schedule's occurrences.
    public func contains(_ date: Date, calendar: Calendar) -> Bool {
        occurrenceEnd(containing: date, calendar: calendar) != nil
    }

    /// The end of the occurrence that contains `date`, if any.
    public func occurrenceEnd(containing date: Date, calendar: Calendar) -> Date? {
        let startOfDay = calendar.startOfDay(for: date)
        // An occurrence that contains `date` started today or (for overnight schedules) yesterday.
        for dayOffset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay) else { continue }
            let weekdayNumber = calendar.component(.weekday, from: day)
            guard let weekday = Weekday(rawValue: weekdayNumber), weekdays.contains(weekday) else { continue }
            guard let occurrenceStart = calendar.date(
                bySettingHour: start.hour, minute: start.minute, second: 0, of: day
            ) else { continue }
            let occurrenceEnd = occurrenceStart.addingTimeInterval(TimeInterval(durationMinutes * 60))
            if date >= occurrenceStart && date < occurrenceEnd {
                return occurrenceEnd
            }
        }
        return nil
    }
}

public enum ScheduleValidationError: Error, Equatable, Sendable {
    case noWeekdays
    case tooShort(minimumMinutes: Int)
    case emptyName
}
