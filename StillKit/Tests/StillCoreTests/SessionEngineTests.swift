import XCTest
@testable import StillCore

final class SessionEngineTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func testStartStoresSession() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        let session = try engine.start(minutes: 30, isStrict: false, now: t0)
        XCTAssertEqual(store.activeSession, session)
        XCTAssertEqual(session.end, t0.addingTimeInterval(1_800))
    }

    func testStartRejectsShortDurationAndKeepsNoSession() {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        XCTAssertThrowsError(try engine.start(minutes: 10, isStrict: false, now: t0))
        XCTAssertNil(store.activeSession)
    }

    func testCannotStartTwice() throws {
        let engine = SessionEngine(store: makeStore())
        try engine.start(minutes: 30, isStrict: false, now: t0)
        XCTAssertThrowsError(try engine.start(minutes: 15, isStrict: false, now: t0.addingTimeInterval(60))) { error in
            XCTAssertEqual(error as? SessionError, .alreadyRunning)
        }
    }

    func testCanStartAfterPreviousExpired() throws {
        let engine = SessionEngine(store: makeStore())
        try engine.start(minutes: 15, isStrict: false, now: t0)
        XCTAssertNoThrow(try engine.start(minutes: 15, isStrict: false, now: t0.addingTimeInterval(16 * 60)))
    }

    func testEndEarlyRecordsPartialMinutes() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        try engine.start(minutes: 30, isStrict: false, now: t0)
        let record = try XCTUnwrap(engine.endEarly(now: t0.addingTimeInterval(12 * 60 + 30)))
        XCTAssertEqual(record.outcome, .endedEarly)
        XCTAssertEqual(record.reclaimedSeconds, 12 * 60 + 30, accuracy: 0.001)
        XCTAssertEqual(record.reclaimedMinutes, 12)
        XCTAssertTrue(record.countsTowardStreak)
        XCTAssertNil(store.activeSession)
        XCTAssertEqual(store.history.count, 1)
        // Early ends don't count as completed sessions and show no "Session complete".
        XCTAssertEqual(store.flags.completedSessionCount, 0)
        XCTAssertNil(store.flags.unseenCompletionID)
    }

    func testShortEarlyEndDoesNotCountTowardStreak() throws {
        let engine = SessionEngine(store: makeStore())
        try engine.start(minutes: 30, isStrict: false, now: t0)
        let record = try XCTUnwrap(engine.endEarly(now: t0.addingTimeInterval(9 * 60 + 59)))
        XCTAssertFalse(record.countsTowardStreak)
    }

    func testStrictSessionCannotEndEarly() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        try engine.start(minutes: 30, isStrict: true, now: t0)
        XCTAssertNil(engine.endEarly(now: t0.addingTimeInterval(60)))
        XCTAssertNotNil(store.activeSession)
    }

    func testCompleteIfExpired() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        let session = try engine.start(minutes: 15, isStrict: false, now: t0)
        XCTAssertNil(engine.completeIfExpired(now: t0.addingTimeInterval(14 * 60)))
        let record = try XCTUnwrap(engine.completeIfExpired(now: t0.addingTimeInterval(3 * 3_600)))
        XCTAssertEqual(record.id, session.id)
        XCTAssertEqual(record.outcome, .completed)
        // Reclaimed time never exceeds the planned duration, even if reconciled hours later.
        XCTAssertEqual(record.reclaimedSeconds, 15 * 60, accuracy: 0.001)
        XCTAssertEqual(store.flags.completedSessionCount, 1)
        XCTAssertEqual(store.flags.unseenCompletionID, session.id)
    }

    func testReconcileExpiredSessionShowsCompletionOnce() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        let session = try engine.start(minutes: 30, isStrict: false, now: t0)

        let result = engine.reconcile(now: t0.addingTimeInterval(45 * 60))
        XCTAssertEqual(result.finalized?.id, session.id)
        XCTAssertNil(result.activeSession)
        XCTAssertTrue(result.shouldClearSessionShield)
        XCTAssertEqual(result.completionToShow?.id, session.id)

        engine.markCompletionSeen()
        let again = engine.reconcile(now: t0.addingTimeInterval(50 * 60))
        XCTAssertNil(again.finalized)
        XCTAssertNil(again.completionToShow)
        XCTAssertEqual(store.history.count, 1)
        XCTAssertEqual(store.flags.completedSessionCount, 1)
    }

    func testReconcileRunningSessionKeepsIt() throws {
        let engine = SessionEngine(store: makeStore())
        let session = try engine.start(minutes: 30, isStrict: false, now: t0)
        let result = engine.reconcile(now: t0.addingTimeInterval(60))
        XCTAssertNil(result.finalized)
        XCTAssertEqual(result.activeSession, session)
        XCTAssertFalse(result.shouldClearSessionShield)
    }

    func testMonitorThenAppFinalizeIsIdempotent() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        let session = try engine.start(minutes: 30, isStrict: false, now: t0)

        // The monitor extension finalizes at intervalDidEnd while the app is not running…
        XCTAssertNotNil(engine.finalize(sessionID: session.id, outcome: .completed, at: session.end))
        // …and the app later reconciles: nothing is recorded twice.
        let result = engine.reconcile(now: session.end.addingTimeInterval(600))
        XCTAssertNil(result.finalized)
        XCTAssertEqual(result.completionToShow?.id, session.id)
        XCTAssertEqual(store.history.count, 1)
        XCTAssertEqual(store.flags.completedSessionCount, 1)
    }

    func testStaleFinalizeDoesNotTouchNewSession() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        let first = try engine.start(minutes: 30, isStrict: false, now: t0)
        engine.endEarly(now: t0.addingTimeInterval(60))
        let second = try engine.start(minutes: 30, isStrict: false, now: t0.addingTimeInterval(120))

        // A late intervalDidEnd for the first session must not end the second one.
        XCTAssertNil(engine.finalize(sessionID: first.id, outcome: .completed, at: first.end))
        XCTAssertEqual(store.activeSession, second)
    }

    func testUrgesAreCountedForTheSession() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        store.recordUrge(at: t0.addingTimeInterval(-60)) // before the session
        let session = try engine.start(minutes: 30, isStrict: false, now: t0)
        store.recordUrge(at: t0.addingTimeInterval(5 * 60))
        store.recordUrge(at: t0.addingTimeInterval(6 * 60))
        XCTAssertEqual(store.urges(during: session, now: t0.addingTimeInterval(10 * 60)), 2)
        let record = try XCTUnwrap(engine.completeIfExpired(now: session.end))
        XCTAssertEqual(record.urgesResisted, 2)
    }

    func testCompletedCountComesFromHistory() throws {
        let store = makeStore()
        let engine = SessionEngine(store: store)
        let session = try engine.start(minutes: 15, isStrict: false, now: t0)
        // Simulate the other process having recorded the same completion already.
        engine.finalize(sessionID: session.id, outcome: .completed, at: session.end)
        store.activeSession = session
        XCTAssertNil(engine.finalize(sessionID: session.id, outcome: .completed, at: session.end))
        XCTAssertEqual(store.flags.completedSessionCount, 1)
        XCTAssertEqual(store.history.count, 1)
    }

    func testSchedulesAllowedFollowsProWithGrace() {
        let store = makeStore()
        XCTAssertFalse(store.schedulesAllowed(at: t0))
        store.proActiveUntil = t0.addingTimeInterval(86_400)
        XCTAssertTrue(store.schedulesAllowed(at: t0))
        XCTAssertTrue(store.schedulesAllowed(at: t0.addingTimeInterval(3 * 86_400)))
        XCTAssertFalse(store.schedulesAllowed(at: t0.addingTimeInterval(4 * 86_400 + 1)))
    }

    func testOldUrgesArePruned() {
        let store = makeStore()
        store.recordUrge(at: t0)
        store.recordUrge(at: t0.addingTimeInterval(61 * 86_400))
        XCTAssertEqual(store.urgeEvents.count, 1)
    }
}
