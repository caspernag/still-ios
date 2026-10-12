import ActivityKit
import Foundation
import StillKit

/// Starts and ends the session Live Activity.
@MainActor
final class LiveActivityService {
    func start(_ session: Session, summary: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = StillActivityAttributes(sessionID: session.id, lockedSummary: summary)
        let content = ActivityContent(
            state: StillActivityAttributes.ContentState(start: session.start, end: session.end),
            staleDate: session.end
        )
        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            // Live Activities are a nice-to-have; the session works without one.
        }
    }

    /// Ends every Still activity except the one for `keeping` (the running session).
    func endAll(keeping activeSessionID: UUID? = nil) {
        // Decide now which activities to end, so one started right after isn't affected.
        let ids = Set(Activity<StillActivityAttributes>.activities
            .filter { $0.attributes.sessionID != activeSessionID }
            .map(\.id))
        guard !ids.isEmpty else { return }
        Task { await Self.endActivities(ids: ids) }
    }

    /// Runs off the main actor so each `Activity` stays in one isolation domain.
    nonisolated private static func endActivities(ids: Set<String>) async {
        for activity in Activity<StillActivityAttributes>.activities where ids.contains(activity.id) {
            let state = StillActivityAttributes.ContentState(
                start: activity.content.state.start,
                end: activity.content.state.end,
                isComplete: true
            )
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}
