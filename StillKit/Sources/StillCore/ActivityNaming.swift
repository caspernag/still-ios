import Foundation

/// Names for DeviceActivity activities and ManagedSettings stores.
///
/// Manual sessions and each schedule use their own ManagedSettingsStore, so they
/// can never clear each other's shields.
public enum ActivityNaming {
    static let sessionPrefix = "still.session."
    static let schedulePrefix = "still.schedule."
    static let dailySuffix = "daily"

    /// The ManagedSettingsStore name for manual sessions.
    public static let sessionStoreName = "still.session"

    /// The ManagedSettingsStore name for one schedule.
    public static func scheduleStoreName(_ scheduleID: UUID) -> String {
        schedulePrefix + scheduleID.uuidString
    }

    /// The DeviceActivity name for one manual session.
    public static func sessionActivityName(_ sessionID: UUID) -> String {
        sessionPrefix + sessionID.uuidString
    }

    /// The DeviceActivity name for one schedule on one weekday (or every day when `weekday` is nil).
    public static func scheduleActivityName(_ scheduleID: UUID, weekday: Weekday?) -> String {
        let suffix = weekday.map { String($0.rawValue) } ?? dailySuffix
        return schedulePrefix + scheduleID.uuidString + "." + suffix
    }

    public enum Parsed: Equatable, Sendable {
        case session(UUID)
        case schedule(UUID, Weekday?)
    }

    /// Parses an activity name created by this type.
    public static func parse(_ name: String) -> Parsed? {
        if name.hasPrefix(sessionPrefix) {
            let rest = String(name.dropFirst(sessionPrefix.count))
            return UUID(uuidString: rest).map(Parsed.session)
        }
        if name.hasPrefix(schedulePrefix) {
            let rest = name.dropFirst(schedulePrefix.count)
            let parts = rest.split(separator: ".", omittingEmptySubsequences: false)
            guard parts.count == 2, let id = UUID(uuidString: String(parts[0])) else { return nil }
            if parts[1] == dailySuffix { return .schedule(id, nil) }
            guard let raw = Int(parts[1]), let weekday = Weekday(rawValue: raw) else { return nil }
            return .schedule(id, weekday)
        }
        return nil
    }
}
