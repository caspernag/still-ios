import Foundation

/// The state machine for manual sessions, independent of the Screen Time frameworks.
///
/// The app and the DeviceActivityMonitor extension both use it, so ending a session
/// on time works the same way whether or not the app is running. All transitions
/// are idempotent: finalizing a session that is no longer active does nothing.
public struct SessionEngine: Sendable {
    public let store: SharedStore

    public init(store: SharedStore) {
        self.store = store
    }

    /// Starts and stores a new session. Throws if one is already running or the
    /// duration is outside 15 min ... 12 h.
    @discardableResult
    public func start(minutes: Int, isStrict: Bool, now: Date, id: UUID = UUID()) throws(SessionError) -> Session {
        if let active = store.activeSession, !SessionMath.isExpired(active, now: now) {
            throw .alreadyRunning
        }
        let session = try SessionMath.makeSession(start: now, minutes: minutes, isStrict: isStrict, id: id)
        store.activeSession = session
        return session
    }

    /// Ends the active session early. Returns the record, or nil if there was no
    /// active session (or it is strict, or it already ran out).
    @discardableResult
    public func endEarly(now: Date) -> SessionRecord? {
        guard let session = store.activeSession, !session.isStrict else { return nil }
        if SessionMath.isExpired(session, now: now) {
            return finalize(sessionID: session.id, outcome: .completed, at: session.end)
        }
        return finalize(sessionID: session.id, outcome: .endedEarly, at: now)
    }

    /// Finalizes the active session if its end time has passed.
    /// Returns the record when this call finalized it.
    @discardableResult
    public func completeIfExpired(now: Date) -> SessionRecord? {
        guard let session = store.activeSession, SessionMath.isExpired(session, now: now) else { return nil }
        return finalize(sessionID: session.id, outcome: .completed, at: session.end)
    }

    /// Finalizes the session with `sessionID` if it is still the active one.
    /// Used by the monitor extension (`intervalDidEnd`) and by the app.
    @discardableResult
    public func finalize(sessionID: UUID, outcome: SessionOutcome, at date: Date) -> SessionRecord? {
        guard let session = store.activeSession, session.id == sessionID else { return nil }
        let actualEnd = outcome == .completed ? session.end : min(max(date, session.start), session.end)
        let record = SessionRecord(
            id: session.id,
            start: session.start,
            plannedEnd: session.end,
            actualEnd: actualEnd,
            outcome: outcome,
            urgesResisted: store.urges(during: session, now: actualEnd),
            isStrict: session.isStrict
        )
        store.activeSession = nil
        guard store.appendRecord(record) else { return nil }
        if outcome == .completed {
            var flags = store.flags
            flags.completedSessionCount += 1
            flags.unseenCompletionID = record.id
            store.flags = flags
        }
        return record
    }

    public struct Reconciliation: Equatable, Sendable {
        /// A session this call finalized because its end time had passed.
        public var finalized: SessionRecord?
        /// The session that is still running, if any.
        public var activeSession: Session?
        /// A completion the user hasn't seen yet ("Session complete" should show).
        public var completionToShow: SessionRecord?

        /// With no running session, any leftover session shield must be cleared.
        public var shouldClearSessionShield: Bool { activeSession == nil }
    }

    /// Brings the stored state up to date. Called on every launch and foreground.
    public func reconcile(now: Date) -> Reconciliation {
        let finalized = completeIfExpired(now: now)
        return Reconciliation(
            finalized: finalized,
            activeSession: store.activeSession,
            completionToShow: unseenCompletion()
        )
    }

    /// The record of the completion the user hasn't seen yet, if any.
    public func unseenCompletion() -> SessionRecord? {
        guard let id = store.flags.unseenCompletionID else { return nil }
        return store.history.first { $0.id == id }
    }

    public func markCompletionSeen() {
        var flags = store.flags
        flags.unseenCompletionID = nil
        store.flags = flags
    }
}
