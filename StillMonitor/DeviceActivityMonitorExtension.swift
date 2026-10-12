import DeviceActivity
import Foundation
import ManagedSettings
import StillKit

/// Runs in its own process, even when Still is not running.
///
/// - Manual sessions: `intervalDidEnd` clears the session shield and records the
///   session as completed in the App Group.
/// - Schedules: `intervalDidStart` applies that schedule's shield and `intervalDidEnd`
///   clears it. Each schedule has its own ManagedSettingsStore, so sessions and
///   schedules never clear each other.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private var store: SharedStore { .shared }

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        switch ActivityNaming.parse(activity.rawValue) {
        case .session(let id)?:
            // The app applies the shield when the session starts; applying again here is
            // harmless and covers the app being killed in between.
            guard let session = store.activeSession, session.id == id,
                  !SessionMath.isExpired(session, now: Date())
            else { return }
            Shields.apply(SelectionStorage.load(from: store), to: .stillSession)

        case .schedule(let id, _)?:
            guard let schedule = store.schedules.first(where: { $0.id == id }), schedule.isEnabled,
                  !store.selectionSummary.isEmpty
            else { return }
            Shields.apply(SelectionStorage.load(from: store), to: .stillSchedule(id))

        case nil:
            break
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        switch ActivityNaming.parse(activity.rawValue) {
        case .session(let id)?:
            if let active = store.activeSession {
                // Only end the session this activity belongs to. A late callback for an
                // older session must never unlock a newer one.
                guard active.id == id else { break }
                SessionEngine(store: store).finalize(sessionID: id, outcome: .completed, at: active.end)
            }
            Shields.clear(.stillSession)
            DeviceActivityCenter().stopMonitoring([activity])

        case .schedule(let id, _)?:
            Shields.clear(.stillSchedule(id))

        case nil:
            break
        }
    }
}
