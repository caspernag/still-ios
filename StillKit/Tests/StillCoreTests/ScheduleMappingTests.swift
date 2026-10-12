import XCTest
@testable import StillCore

final class ScheduleMappingTests: XCTestCase {
    func testWeekdaySchedulesMapToOneIntervalPerDay() {
        let schedule = StillSchedule(
            name: "Work",
            start: TimeOfDay(hour: 9, minute: 0),
            end: TimeOfDay(hour: 17, minute: 30),
            weekdays: [.monday, .wednesday, .friday],
            isEnabled: true
        )
        let intervals = ScheduleMapping.intervals(for: schedule)
        XCTAssertEqual(intervals.count, 3)
        XCTAssertEqual(intervals.map { $0.intervalStart.weekday }, [2, 4, 6])
        XCTAssertEqual(intervals.map { $0.intervalEnd.weekday }, [2, 4, 6])
        XCTAssertTrue(intervals.allSatisfy { $0.repeats })
        XCTAssertEqual(intervals[0].intervalStart.hour, 9)
        XCTAssertEqual(intervals[0].intervalStart.minute, 0)
        XCTAssertEqual(intervals[0].intervalEnd.hour, 17)
        XCTAssertEqual(intervals[0].intervalEnd.minute, 30)
        XCTAssertEqual(Set(intervals.map(\.activityName)).count, 3)
    }

    func testOvernightScheduleEndsOnTheNextWeekday() {
        let schedule = StillSchedule(
            name: "Weekend nights",
            start: TimeOfDay(hour: 23, minute: 0),
            end: TimeOfDay(hour: 8, minute: 0),
            weekdays: [.friday, .saturday],
            isEnabled: true
        )
        let intervals = ScheduleMapping.intervals(for: schedule)
        XCTAssertEqual(intervals.map { $0.intervalStart.weekday }, [6, 7])
        // Saturday night ends on Sunday (wraps 7 -> 1).
        XCTAssertEqual(intervals.map { $0.intervalEnd.weekday }, [7, 1])
        XCTAssertTrue(schedule.crossesMidnight)
        XCTAssertEqual(schedule.durationMinutes, 9 * 60)
    }

    func testEveryDayCollapsesToOneDailyInterval() {
        var nights = StillSchedule.nightsExample()
        nights.isEnabled = true
        let intervals = ScheduleMapping.intervals(for: nights)
        XCTAssertEqual(intervals.count, 1)
        XCTAssertNil(intervals[0].intervalStart.weekday)
        XCTAssertEqual(intervals[0].intervalStart.hour, 22)
        XCTAssertEqual(intervals[0].intervalEnd.hour, 7)
        XCTAssertEqual(ActivityNaming.parse(intervals[0].activityName), .schedule(nights.id, nil))
    }

    func testSeededExampleIsNightsAndOff() {
        let nights = StillSchedule.nightsExample()
        XCTAssertEqual(nights.name, "Nights")
        XCTAssertEqual(nights.start, TimeOfDay(hour: 22, minute: 0))
        XCTAssertEqual(nights.end, TimeOfDay(hour: 7, minute: 0))
        XCTAssertFalse(nights.isEnabled)
        XCTAssertEqual(ScheduleMapping.intervals(forEnabled: [nights]).count, 0)
    }

    func testValidation() {
        var schedule = StillSchedule(
            name: "Short", start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 9, minute: 10),
            weekdays: [.monday], isEnabled: true
        )
        XCTAssertEqual(ScheduleMapping.validate(schedule), .tooShort(minimumMinutes: 15))
        XCTAssertTrue(ScheduleMapping.intervals(for: schedule).isEmpty)

        schedule.end = TimeOfDay(hour: 9, minute: 15)
        XCTAssertNil(ScheduleMapping.validate(schedule))

        schedule.end = schedule.start
        XCTAssertEqual(ScheduleMapping.validate(schedule), .tooShort(minimumMinutes: 15))

        schedule.end = TimeOfDay(hour: 10, minute: 0)
        schedule.weekdays = []
        XCTAssertEqual(ScheduleMapping.validate(schedule), .noWeekdays)

        schedule.weekdays = [.monday]
        schedule.name = "  "
        XCTAssertEqual(ScheduleMapping.validate(schedule), .emptyName)
    }

    func testActivityNamesRoundTrip() {
        let id = UUID()
        XCTAssertEqual(ActivityNaming.parse(ActivityNaming.sessionActivityName(id)), .session(id))
        XCTAssertEqual(ActivityNaming.parse(ActivityNaming.scheduleActivityName(id, weekday: .tuesday)), .schedule(id, .tuesday))
        XCTAssertEqual(ActivityNaming.parse(ActivityNaming.scheduleActivityName(id, weekday: nil)), .schedule(id, nil))
        XCTAssertNil(ActivityNaming.parse("something.else"))
        XCTAssertNil(ActivityNaming.parse("still.schedule.not-a-uuid.3"))
        XCTAssertNil(ActivityNaming.parse("still.schedule.\(id.uuidString).9"))
        XCTAssertNotEqual(ActivityNaming.sessionStoreName, ActivityNaming.scheduleStoreName(id))
    }

    func testActivityBudget() {
        func weekly(_ days: Set<Weekday>) -> StillSchedule {
            StillSchedule(name: "S", start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 10, minute: 0), weekdays: days, isEnabled: true)
        }
        let sixDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        let three = [weekly(sixDays), weekly(sixDays), weekly(sixDays)] // 18 activities
        XCTAssertEqual(ScheduleMapping.activityCount(three), 18)
        XCTAssertTrue(ScheduleMapping.fitsActivityBudget(three))
        XCTAssertFalse(ScheduleMapping.fitsActivityBudget(three + [weekly([.monday, .tuesday])]))
        // Every-day schedules only need one activity each.
        XCTAssertTrue(ScheduleMapping.fitsActivityBudget(Array(repeating: weekly(Set(Weekday.allCases)), count: 19)))
    }

    func testActiveScheduleAndOccurrenceEnd() {
        let oslo = calendar("Europe/Oslo")
        var nights = StillSchedule.nightsExample()
        nights.isEnabled = true
        nights.weekdays = [.monday] // Monday 22:00 -> Tuesday 07:00

        // Monday Oct 12, 2026 23:00 is inside.
        let end = nights.occurrenceEnd(containing: date(2026, 10, 12, 23, in: oslo), calendar: oslo)
        XCTAssertEqual(end, date(2026, 10, 13, 7, in: oslo))
        // Tuesday 06:59 is still inside (started Monday).
        XCTAssertTrue(nights.contains(date(2026, 10, 13, 6, 59, in: oslo), calendar: oslo))
        // Tuesday 07:00 and Tuesday 23:00 are outside.
        XCTAssertFalse(nights.contains(date(2026, 10, 13, 7, 0, in: oslo), calendar: oslo))
        XCTAssertFalse(nights.contains(date(2026, 10, 13, 23, 0, in: oslo), calendar: oslo))

        let active = ScheduleMapping.activeSchedule(in: [nights], at: date(2026, 10, 12, 22, 30, in: oslo), calendar: oslo)
        XCTAssertEqual(active?.schedule.id, nights.id)
        nights.isEnabled = false
        XCTAssertNil(ScheduleMapping.activeSchedule(in: [nights], at: date(2026, 10, 12, 22, 30, in: oslo), calendar: oslo))
    }

    func testAllOverlappingSchedulesAreActive() {
        let oslo = calendar("Europe/Oslo")
        var nights = StillSchedule.nightsExample()
        nights.isEnabled = true
        let evening = StillSchedule(
            name: "Evening", start: TimeOfDay(hour: 21, minute: 0), end: TimeOfDay(hour: 23, minute: 0),
            weekdays: Set(Weekday.allCases), isEnabled: true
        )
        let active = ScheduleMapping.activeSchedules(in: [nights, evening], at: date(2026, 10, 12, 22, 30, in: oslo), calendar: oslo)
        XCTAssertEqual(Set(active.map(\.schedule.id)), [nights.id, evening.id])
    }

    func testWeekdayOrdering() {
        XCTAssertEqual(Weekday.ordered(firstWeekday: 2).first, .monday)
        XCTAssertEqual(Weekday.ordered(firstWeekday: 2).last, .sunday)
        XCTAssertEqual(Weekday.ordered(firstWeekday: 1).first, .sunday)
        XCTAssertEqual(Weekday.saturday.next, .sunday)
    }

    func testSchedulesPersistInStore() {
        let store = makeStore()
        let nights = StillSchedule.nightsExample()
        store.schedules = [nights]
        XCTAssertEqual(store.schedules, [nights])
    }
}
