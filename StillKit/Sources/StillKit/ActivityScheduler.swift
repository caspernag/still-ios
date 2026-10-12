#if os(iOS)
import DeviceActivity
import Foundation

extension DeviceActivityName {
    public static func stillSession(_ sessionID: UUID) -> Self {
        Self(ActivityNaming.sessionActivityName(sessionID))
    }
}

public enum ActivitySchedulerError: Error, Equatable {
    /// Too many enabled schedules for DeviceActivityCenter's limit of 20 activities.
    case tooManySchedules
}

/// Registers manual sessions and schedules with DeviceActivityCenter.
public enum ActivityScheduler {
    /// Monitors a one-off interval from the session's start to its end, so the
    /// monitor extension's `intervalDidEnd` clears the shield even if the app is not running.
    public static func startMonitoring(_ session: Session, calendar: Calendar = .current) throws {
        let components: Set<Calendar.Component> = [.calendar, .timeZone, .year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(components, from: session.start),
            intervalEnd: calendar.dateComponents(components, from: session.end),
            repeats: false
        )
        try DeviceActivityCenter().startMonitoring(.stillSession(session.id), during: schedule)
    }

    public static func stopMonitoring(_ sessionID: UUID) {
        DeviceActivityCenter().stopMonitoring([.stillSession(sessionID)])
    }

    /// Stops every session activity (used when reconciling leftovers).
    public static func stopAllSessionActivities() {
        let center = DeviceActivityCenter()
        let names = center.activities.filter {
            if case .session = ActivityNaming.parse($0.rawValue) { return true }
            return false
        }
        if !names.isEmpty { center.stopMonitoring(names) }
    }

    /// Re-registers every enabled schedule. Each one gets its own activity per
    /// weekday (or one daily activity when every day is selected).
    /// Returns the schedule IDs that are no longer monitored, so their shields can be cleared.
    @discardableResult
    public static func registerSchedules(_ schedules: [StillSchedule]) throws -> Set<UUID> {
        guard ScheduleMapping.fitsActivityBudget(schedules) else { throw ActivitySchedulerError.tooManySchedules }

        let center = DeviceActivityCenter()
        var previouslyMonitored = Set<UUID>()
        let scheduleActivities = center.activities.filter {
            if case .schedule(let id, _) = ActivityNaming.parse($0.rawValue) {
                previouslyMonitored.insert(id)
                return true
            }
            return false
        }
        if !scheduleActivities.isEmpty { center.stopMonitoring(scheduleActivities) }

        var monitored = Set<UUID>()
        for schedule in schedules where schedule.isEnabled {
            for interval in ScheduleMapping.intervals(for: schedule) {
                let deviceSchedule = DeviceActivitySchedule(
                    intervalStart: interval.intervalStart,
                    intervalEnd: interval.intervalEnd,
                    repeats: interval.repeats
                )
                try center.startMonitoring(DeviceActivityName(interval.activityName), during: deviceSchedule)
                monitored.insert(schedule.id)
            }
        }
        return previouslyMonitored.subtracting(monitored)
    }
}
#endif
