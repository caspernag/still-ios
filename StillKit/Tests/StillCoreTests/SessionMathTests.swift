import XCTest
@testable import StillCore

final class SessionMathTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testMakeSessionComputesEnd() throws {
        let session = try SessionMath.makeSession(start: start, minutes: 30, isStrict: false)
        XCTAssertEqual(session.start, start)
        XCTAssertEqual(session.end, start.addingTimeInterval(30 * 60))
        XCTAssertEqual(session.plannedMinutes, 30)
        XCTAssertFalse(session.isStrict)
    }

    func testFifteenMinuteMinimumIsEnforced() {
        XCTAssertThrowsError(try SessionMath.makeSession(start: start, minutes: 14, isStrict: false)) { error in
            XCTAssertEqual(error as? SessionError, .tooShort(minimumMinutes: 15))
        }
        XCTAssertThrowsError(try SessionMath.validate(minutes: 0))
        XCTAssertThrowsError(try SessionMath.validate(minutes: -30))
        XCTAssertNoThrow(try SessionMath.validate(minutes: 15))
        XCTAssertNoThrow(try SessionMath.makeSession(start: start, minutes: 15, isStrict: true))
    }

    func testTwelveHourMaximumIsEnforced() {
        XCTAssertNoThrow(try SessionMath.validate(minutes: 720))
        XCTAssertThrowsError(try SessionMath.validate(minutes: 721)) { error in
            XCTAssertEqual(error as? SessionError, .tooLong(maximumMinutes: 720))
        }
    }

    func testClamp() {
        XCTAssertEqual(SessionMath.clamp(minutes: 5), 15)
        XCTAssertEqual(SessionMath.clamp(minutes: 45), 45)
        XCTAssertEqual(SessionMath.clamp(minutes: 2_000), 720)
    }

    func testRemainingAndProgress() throws {
        let session = try SessionMath.makeSession(start: start, minutes: 30, isStrict: false)
        let tenIn = start.addingTimeInterval(10 * 60)
        XCTAssertEqual(SessionMath.remaining(session, now: tenIn), 20 * 60, accuracy: 0.001)
        XCTAssertEqual(SessionMath.progress(session, now: tenIn), 1.0 / 3.0, accuracy: 0.0001)
        XCTAssertEqual(SessionMath.remainingFraction(session, now: tenIn), 2.0 / 3.0, accuracy: 0.0001)
        XCTAssertFalse(SessionMath.isExpired(session, now: tenIn))

        // Before start and after end are clamped.
        XCTAssertEqual(SessionMath.progress(session, now: start.addingTimeInterval(-60)), 0)
        XCTAssertEqual(SessionMath.progress(session, now: session.end.addingTimeInterval(600)), 1)
        XCTAssertEqual(SessionMath.remaining(session, now: session.end.addingTimeInterval(600)), 0)
        XCTAssertTrue(SessionMath.isExpired(session, now: session.end))
    }

    func testHoursAndMinutes() {
        XCTAssertTrue(SessionMath.hoursAndMinutes(105) == (1, 45))
        XCTAssertTrue(SessionMath.hoursAndMinutes(60) == (1, 0))
        XCTAssertTrue(SessionMath.hoursAndMinutes(0) == (0, 0))
        XCTAssertTrue(SessionMath.hoursAndMinutes(-5) == (0, 0))
    }

    func testDurationTextStyle() {
        XCTAssertEqual(DurationText.style(minutes: 45), .minutes(45))
        XCTAssertEqual(DurationText.style(minutes: 120), .hours(2))
        XCTAssertEqual(DurationText.style(minutes: 192), .hoursMinutes(3, 12))
        XCTAssertEqual(DurationText.style(seconds: 59), .minutes(0))
        XCTAssertEqual(DurationText.style(seconds: 3_700), .hoursMinutes(1, 1))
    }
}
