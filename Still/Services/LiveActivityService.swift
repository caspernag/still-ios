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
        Task { await Self.endActivities(keeping: activeSessionID) }
    }

    /// Runs off the main actor so each `Activity` stays in one isolation domain.
    nonisolated private static func endActivities(keeping activeSessionID: UUID?) async {
        for activity in Activity<StillActivityAttributes>.activities where activity.attributes.sessionID != activeSessionID {
            let state = StillActivityAttributes.ContentState(
                start: activity.content.state.start,
                end: activity.content.state.end,
                isComplete: true
            )
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}
