import Foundation

/// One repeating DeviceActivity interval, described with plain DateComponents
/// so the mapping can be unit tested without the DeviceActivity framework.
public struct ActivityInterval: Hashable, Sendable {
    public var activityName: String
    public var intervalStart: DateComponents
    public var intervalEnd: DateComponents
    public var repeats: Bool
}

/// Maps schedules to DeviceActivity intervals.
public enum ScheduleMapping {
    /// Validates a schedule before it is saved or registered.
    public static func validate(_ schedule: StillSchedule) -> ScheduleValidationError? {
        if schedule.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return .emptyName }
        if schedule.weekdays.isEmpty { return .noWeekdays }
        if schedule.start == schedule.end || schedule.durationMinutes < StillConstants.minimumSessionMinutes {
            return .tooShort(minimumMinutes: StillConstants.minimumSessionMinutes)
        }
        return nil
    }

    /// The intervals to register for one schedule.
    ///
    /// Each selected weekday becomes its own weekly repeating interval. When every
    /// day is selected the schedule collapses into one daily repeating interval,
    /// which saves 6 of the 20 activities DeviceActivityCenter allows.
    /// Overnight schedules (e.g. 22:00–07:00) end on the following weekday.
    public static func intervals(for schedule: StillSchedule) -> [ActivityInterval] {
        guard validate(schedule) == nil else { return [] }

        if schedule.weekdays.count == Weekday.allCases.count {
            return [
                ActivityInterval(
                    activityName: ActivityNaming.scheduleActivityName(schedule.id, weekday: nil),
                    intervalStart: DateComponents(hour: schedule.start.hour, minute: schedule.start.minute),
                    intervalEnd: DateComponents(hour: schedule.end.hour, minute: schedule.end.minute),
                    repeats: true
                ),
            ]
        }

        return schedule.weekdays.sorted().map { weekday in
            let endWeekday = schedule.crossesMidnight ? weekday.next : weekday
            return ActivityInterval(
                activityName: ActivityNaming.scheduleActivityName(schedule.id, weekday: weekday),
                intervalStart: DateComponents(
                    hour: schedule.start.hour, minute: schedule.start.minute, weekday: weekday.rawValue
                ),
                intervalEnd: DateComponents(
                    hour: schedule.end.hour, minute: schedule.end.minute, weekday: endWeekday.rawValue
                ),
                repeats: true
            )
        }
    }

    /// All intervals for the enabled schedules.
    public static func intervals(forEnabled schedules: [StillSchedule]) -> [ActivityInterval] {
        schedules.filter(\.isEnabled).flatMap(intervals(for:))
    }

    /// How many activities the enabled schedules need.
    public static func activityCount(_ schedules: [StillSchedule]) -> Int {
        intervals(forEnabled: schedules).count
    }

    /// Whether the enabled schedules fit next to one manual session within the system limit.
    public static func fitsActivityBudget(_ schedules: [StillSchedule]) -> Bool {
        activityCount(schedules) <= StillConstants.maximumMonitoredActivities - 1
    }

    /// The enabled schedule that is active at `date`, with the end of its current occurrence.
    public static func activeSchedule(
        in schedules: [StillSchedule],
        at date: Date,
        calendar: Calendar
    ) -> (schedule: StillSchedule, end: Date)? {
        for schedule in schedules where schedule.isEnabled {
            if let end = schedule.occurrenceEnd(containing: date, calendar: calendar) {
                return (schedule, end)
            }
        }
        return nil
    }
}
