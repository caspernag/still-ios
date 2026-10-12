import Foundation
@testable import StillCore

/// A SharedStore backed by a throwaway UserDefaults suite.
func makeStore(file: StaticString = #filePath, line: UInt = #line) -> SharedStore {
    let suite = "still.tests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    return SharedStore(defaults: defaults)
}

/// A Gregorian calendar in a fixed time zone.
func calendar(_ identifier: String, firstWeekday: Int = 2) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: identifier)!
    calendar.firstWeekday = firstWeekday
    return calendar
}

/// Builds a date from components in the given calendar.
func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0, in calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// A finished record that started at `start` and lasted `minutes`.
func makeRecord(
    start: Date,
    minutes: Double,
    planned: Double? = nil,
    outcome: SessionOutcome = .completed,
    urges: Int = 0
) -> SessionRecord {
    let plannedEnd = start.addingTimeInterval((planned ?? minutes) * 60)
    return SessionRecord(
        id: UUID(),
        start: start,
        plannedEnd: plannedEnd,
        actualEnd: start.addingTimeInterval(minutes * 60),
        outcome: outcome,
        urgesResisted: urges
    )
}
