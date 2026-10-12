import Foundation

/// User settings.
public struct StillSettings: Codable, Hashable, Sendable {
    public var isStrictMode: Bool = false
    public var notifyWhenDone: Bool = true
    /// The selected preset (or custom) duration in minutes.
    public var durationMinutes: Int = StillConstants.defaultDurationMinutes
    /// Whether `durationMinutes` came from the custom picker (Pro).
    public var isCustomDuration: Bool = false

    public init() {}
}

/// One-off flags.
public struct StillFlags: Codable, Hashable, Sendable {
    public var hasCompletedOnboarding: Bool = false
    public var hasSeenAutomaticPaywall: Bool = false
    public var hasRequestedReview: Bool = false
    public var hasRequestedNotificationPermission: Bool = false
    public var hasSeededSchedules: Bool = false
    /// Completed sessions whose "Session complete" screen the user hasn't seen yet.
    public var unseenCompletionID: UUID?
    /// Total completed sessions (timer ran out), used for the paywall and review prompts.
    public var completedSessionCount: Int = 0

    public init() {}
}

/// Counts of what is selected. FamilyActivitySelection itself is opaque, so the
/// counts are stored next to it for the widget, extensions and Home.
public struct SelectionSummary: Codable, Hashable, Sendable {
    public var applications: Int
    public var categories: Int
    public var webDomains: Int

    public init(applications: Int = 0, categories: Int = 0, webDomains: Int = 0) {
        self.applications = applications
        self.categories = categories
        self.webDomains = webDomains
    }

    public var isEmpty: Bool { applications + categories + webDomains == 0 }
    public var total: Int { applications + categories + webDomains }
}

/// Codable storage in the App Group's UserDefaults, shared by the app and every extension.
///
/// Each value lives under its own key so that a write from one process (for example the
/// ShieldAction extension counting an urge) never overwrites another process's data.
public final class SharedStore: @unchecked Sendable {
    public enum Key: String, CaseIterable, Sendable {
        case activeSession = "still.activeSession"
        case history = "still.history"
        case settings = "still.settings"
        case flags = "still.flags"
        case schedules = "still.schedules"
        case selection = "still.selection"
        case selectionSummary = "still.selectionSummary"
        case urgeEvents = "still.urgeEvents"
        case proActiveUntil = "still.proActiveUntil"
    }

    public let defaults: UserDefaults
    private let lock = NSLock()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// The store backed by the App Group. Falls back to standard defaults if the
    /// group container is unavailable (for example in unsigned builds).
    public static let shared = SharedStore(
        defaults: UserDefaults(suiteName: StillConstants.appGroup) ?? .standard
    )

    // MARK: Generic access

    public func value<T: Codable>(_ type: T.Type, for key: Key) -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    public func set<T: Codable>(_ value: T?, for key: Key) {
        lock.lock()
        defer { lock.unlock() }
        if let value, let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key.rawValue)
        } else {
            defaults.removeObject(forKey: key.rawValue)
        }
    }

    /// Read-modify-write under the lock.
    public func update<T: Codable>(_ key: Key, default defaultValue: T, _ transform: (inout T) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        var value = defaults.data(forKey: key.rawValue).flatMap { try? decoder.decode(T.self, from: $0) } ?? defaultValue
        transform(&value)
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key.rawValue)
        }
    }

    // MARK: Typed accessors

    public var activeSession: Session? {
        get { value(Session.self, for: .activeSession) }
        set { set(newValue, for: .activeSession) }
    }

    public var history: [SessionRecord] {
        get { value([SessionRecord].self, for: .history) ?? [] }
        set { set(newValue, for: .history) }
    }

    public var settings: StillSettings {
        get { value(StillSettings.self, for: .settings) ?? StillSettings() }
        set { set(newValue, for: .settings) }
    }

    public var flags: StillFlags {
        get { value(StillFlags.self, for: .flags) ?? StillFlags() }
        set { set(newValue, for: .flags) }
    }

    public var schedules: [StillSchedule] {
        get { value([StillSchedule].self, for: .schedules) ?? [] }
        set { set(newValue, for: .schedules) }
    }

    /// The encoded FamilyActivitySelection (opaque to StillCore).
    public var selectionData: Data? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return defaults.data(forKey: Key.selection.rawValue)
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            defaults.set(newValue, forKey: Key.selection.rawValue)
        }
    }

    public var selectionSummary: SelectionSummary {
        get { value(SelectionSummary.self, for: .selectionSummary) ?? SelectionSummary() }
        set { set(newValue, for: .selectionSummary) }
    }

    /// When the current Still Pro period ends (written by the app). The monitor extension
    /// uses it so schedules stop locking after Pro lapses, even if the app isn't opened.
    public var proActiveUntil: Date? {
        get { value(Date.self, for: .proActiveUntil) }
        set { set(newValue, for: .proActiveUntil) }
    }

    /// Whether schedules may run at `date`. Allows a 3-day grace period, because
    /// renewals are only seen when the app runs.
    public func schedulesAllowed(at date: Date) -> Bool {
        guard let until = proActiveUntil else { return false }
        return until.addingTimeInterval(3 * 86_400) > date
    }

    // MARK: Urges

    /// Times the user tapped "Close" on the shield. Kept for 60 days.
    public var urgeEvents: [Date] {
        value([Date].self, for: .urgeEvents) ?? []
    }

    /// Records one resisted urge. Called from the ShieldAction extension.
    public func recordUrge(at date: Date) {
        let cutoff = date.addingTimeInterval(-60 * 86_400)
        update(.urgeEvents, default: [Date]()) { events in
            events.append(date)
            events.removeAll { $0 < cutoff }
        }
    }

    /// Urges recorded during a session's interval, up to `now`.
    public func urges(during session: Session, now: Date) -> Int {
        let end = min(now, session.end)
        guard end > session.start else { return 0 }
        return Stats.urges(events: urgeEvents, in: DateInterval(start: session.start, end: end))
    }

    // MARK: History

    /// Appends a record unless one with the same id already exists. Returns true if appended.
    @discardableResult
    public func appendRecord(_ record: SessionRecord) -> Bool {
        var appended = false
        update(.history, default: [SessionRecord]()) { history in
            guard !history.contains(where: { $0.id == record.id }) else { return }
            history.append(record)
            appended = true
        }
        return appended
    }

    /// Removes every value. Used by tests and demo mode.
    public func reset() {
        for key in Key.allCases {
            defaults.removeObject(forKey: key.rawValue)
        }
    }
}
