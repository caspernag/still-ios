import XCTest
@testable import StillCore

final class StatsTests: XCTestCase {
    let oslo = calendar("Europe/Oslo")

    func testStreakCountsConsecutiveDays() {
        let records = [
            record(start: date(2026, 10, 10, 9, in: oslo), minutes: 30),
            record(start: date(2026, 10, 11, 21, in: oslo), minutes: 15),
            record(start: date(2026, 10, 12, 8, in: oslo), minutes: 60),
        ]
        XCTAssertEqual(Stats.streak(records: records, now: date(2026, 10, 12, 20, in: oslo), calendar: oslo), 3)
    }

    func testStreakSurvivesUntilEndOfNextDay() {
        let records = [
            record(start: date(2026, 10, 10, 9, in: oslo), minutes: 30),
            record(start: date(2026, 10, 11, 9, in: oslo), minutes: 30),
        ]
        // Nothing yet today: the streak from yesterday still stands.
        XCTAssertEqual(Stats.streak(records: records, now: date(2026, 10, 12, 23, 59, in: oslo), calendar: oslo), 2)
        // A full day without a session breaks it.
        XCTAssertEqual(Stats.streak(records: records, now: date(2026, 10, 13, 0, 1, in: oslo), calendar: oslo), 0)
    }

    func testGapBreaksStreak() {
        let records = [
            record(start: date(2026, 10, 8, in: oslo), minutes: 30),
            record(start: date(2026, 10, 10, in: oslo), minutes: 30),
            record(start: date(2026, 10, 11, in: oslo), minutes: 30),
        ]
        XCTAssertEqual(Stats.streak(records: records, now: date(2026, 10, 11, 18, in: oslo), calendar: oslo), 2)
    }

    func testMultipleSessionsSameDayCountOnce() {
        let records = [
            record(start: date(2026, 10, 12, 8, in: oslo), minutes: 30),
            record(start: date(2026, 10, 12, 12, in: oslo), minutes: 30),
            record(start: date(2026, 10, 12, 18, in: oslo), minutes: 30),
        ]
        XCTAssertEqual(Stats.streak(records: records, now: date(2026, 10, 12, 20, in: oslo), calendar: oslo), 1)
    }

    func testEarlyEndsUnderTenMinutesDoNotCount() {
        let records = [
            record(start: date(2026, 10, 11, in: oslo), minutes: 9, planned: 30, outcome: .endedEarly),
            record(start: date(2026, 10, 12, in: oslo), minutes: 10, planned: 30, outcome: .endedEarly),
        ]
        XCTAssertEqual(Stats.streak(records: records, now: date(2026, 10, 12, 20, in: oslo), calendar: oslo), 1)
    }

    func testEmptyHistoryHasNoStreak() {
        XCTAssertEqual(Stats.streak(records: [], now: Date(), calendar: oslo), 0)
    }

    func testStreakFollowsTheCalendarsTimeZone() {
        // 23:30 in Oslo on Oct 10 and 23:30 in Oslo on Oct 11 (UTC+2 in October).
        let first = record(start: date(2026, 10, 10, 23, 30, in: oslo), minutes: 20)
        let second = record(start: date(2026, 10, 11, 23, 30, in: oslo), minutes: 20)
        let now = date(2026, 10, 12, 9, in: oslo)

        // In Oslo these are two consecutive days (Oct 10 and 11), still alive on Oct 12.
        XCTAssertEqual(Stats.streak(records: [first, second], now: now, calendar: oslo), 2)

        // Seen from Tokyo (UTC+9) both sessions fall on the next day (Oct 11 and 12, 06:30).
        let tokyo = calendar("Asia/Tokyo")
        XCTAssertEqual(Stats.day(of: first, calendar: tokyo), date(2026, 10, 11, 0, in: tokyo))
        XCTAssertEqual(Stats.streak(records: [first, second], now: now, calendar: tokyo), 2)

        // Seen from New York (UTC-4) they are 17:30 on Oct 10 and Oct 11; `now` is 03:00 Oct 12,
        // so the streak is alive but today has nothing yet.
        let newYork = calendar("America/New_York")
        XCTAssertEqual(Stats.streak(records: [first, second], now: now, calendar: newYork), 2)
    }

    func testStreakAcrossDaylightSavingChange() {
        // Norway leaves summer time on Oct 25, 2026 (a 25-hour day).
        let records = [
            record(start: date(2026, 10, 24, 22, in: oslo), minutes: 30),
            record(start: date(2026, 10, 25, 22, in: oslo), minutes: 30),
            record(start: date(2026, 10, 26, 22, in: oslo), minutes: 30),
        ]
        XCTAssertEqual(Stats.streak(records: records, now: date(2026, 10, 26, 23, in: oslo), calendar: oslo), 3)
    }

    func testReclaimedIncludesPartialMinutesFromEarlyEnds() {
        let records = [
            record(start: date(2026, 10, 12, 8, in: oslo), minutes: 30),
            record(start: date(2026, 10, 12, 10, in: oslo), minutes: 12.5, planned: 60, outcome: .endedEarly),
            record(start: date(2026, 10, 12, 12, in: oslo), minutes: 0.5, planned: 60, outcome: .endedEarly),
        ]
        XCTAssertEqual(Stats.reclaimedSeconds(records: records), 30 * 60 + 12.5 * 60 + 30, accuracy: 0.001)
        XCTAssertEqual(Int(Stats.reclaimedSeconds(records: records) / 60), 43)
    }

    func testReclaimedNeverExceedsPlanned() {
        let start = date(2026, 10, 12, 8, in: oslo)
        let over = SessionRecord(
            id: UUID(), start: start, plannedEnd: start.addingTimeInterval(900),
            actualEnd: start.addingTimeInterval(9_000), outcome: .completed
        )
        XCTAssertEqual(over.reclaimedSeconds, 900)
    }

    func testThisWeekUsesMondayAsFirstDayInNorway() {
        // Oct 12, 2026 is a Monday.
        let records = [
            record(start: date(2026, 10, 11, 20, in: oslo), minutes: 60), // Sunday, last week
            record(start: date(2026, 10, 12, 8, in: oslo), minutes: 30), // Monday
            record(start: date(2026, 10, 14, 8, in: oslo), minutes: 15), // Wednesday
        ]
        let seconds = Stats.thisWeekSeconds(records: records, now: date(2026, 10, 14, 20, in: oslo), calendar: oslo)
        XCTAssertEqual(seconds, 45 * 60, accuracy: 0.001)

        // With Sunday as first weekday (US), Sunday's hour belongs to this week too.
        var us = oslo
        us.firstWeekday = 1
        XCTAssertEqual(
            Stats.thisWeekSeconds(records: records, now: date(2026, 10, 14, 20, in: oslo), calendar: us),
            105 * 60, accuracy: 0.001
        )
    }

    func testDailyTotalsCoverSevenDaysOldestFirst() {
        let now = date(2026, 10, 12, 20, in: oslo)
        let records = [
            record(start: date(2026, 10, 12, 8, in: oslo), minutes: 30),
            record(start: date(2026, 10, 12, 9, in: oslo), minutes: 15),
            record(start: date(2026, 10, 6, 9, in: oslo), minutes: 60),
            record(start: date(2026, 10, 5, 9, in: oslo), minutes: 60), // 8 days ago: outside
        ]
        let totals = Stats.dailyTotals(records: records, days: 7, now: now, calendar: oslo)
        XCTAssertEqual(totals.count, 7)
        XCTAssertEqual(totals.first?.day, date(2026, 10, 6, 0, in: oslo))
        XCTAssertEqual(totals.first?.minutes, 60)
        XCTAssertEqual(totals.last?.day, date(2026, 10, 12, 0, in: oslo))
        XCTAssertEqual(totals.last?.minutes, 45)
        XCTAssertEqual(totals.last?.sessions, 2)
        XCTAssertEqual(totals.map(\.minutes).reduce(0, +), 105)
    }

    func testLastDaysIntervalAndCounts() {
        let now = date(2026, 10, 12, 20, in: oslo)
        let interval = Stats.lastDays(7, now: now, calendar: oslo)
        XCTAssertEqual(interval.start, date(2026, 10, 6, 0, in: oslo))
        XCTAssertEqual(interval.end, date(2026, 10, 13, 0, in: oslo))

        let events = [date(2026, 10, 5, 23, in: oslo), date(2026, 10, 6, 1, in: oslo), date(2026, 10, 12, 19, in: oslo)]
        XCTAssertEqual(Stats.urges(events: events, in: interval), 2)

        let records = [record(start: date(2026, 10, 6, 9, in: oslo), minutes: 30), record(start: date(2026, 10, 1, in: oslo), minutes: 30)]
        XCTAssertEqual(Stats.sessionCount(records: records, in: interval), 1)
    }
}
