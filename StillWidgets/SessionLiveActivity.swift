import ActivityKit
import DesignSystem
import StillKit
import SwiftUI
import WidgetKit

/// Screen 12: the session Live Activity on the Lock Screen and in the Dynamic Island.
///
/// The countdown uses `Text(timerInterval:)`, so it needs no updates. The activity's
/// `staleDate` is the session end; once stale it shows "Session complete".
struct SessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StillActivityAttributes.self) { context in
            LiveActivityViews.LockScreen(
                start: context.state.start,
                end: context.state.end,
                isComplete: context.state.isComplete || context.isStale,
                summary: context.attributes.lockedSummary
            )
            .activityBackgroundTint(StillColor.surface.opacity(0.88))
            .activitySystemActionForegroundColor(StillColor.ink)
        } dynamicIsland: { context in
            let isComplete = context.state.isComplete || context.isStale
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveActivityViews.ExpandedLeading()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveActivityViews.ExpandedTrailing(end: context.state.end, isComplete: isComplete)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityViews.ExpandedBottom(
                        start: context.state.start,
                        end: context.state.end,
                        isComplete: isComplete
                    )
                }
            } compactLeading: {
                LiveActivityViews.CompactLeading()
            } compactTrailing: {
                LiveActivityViews.CompactTrailing(
                    start: context.state.start,
                    end: context.state.end,
                    isComplete: isComplete
                )
            } minimal: {
                LiveActivityViews.Minimal(isComplete: isComplete)
            }
            .keylineTint(StillColor.accent)
        }
    }
}

#if DEBUG
#Preview("Lock Screen", as: .content, using: StillActivityAttributes(sessionID: UUID(), lockedSummary: "3 categories locked")) {
    SessionLiveActivity()
} contentStates: {
    StillActivityAttributes.ContentState(start: .now, end: .now.addingTimeInterval(24 * 60 + 18))
    StillActivityAttributes.ContentState(start: .now, end: .now, isComplete: true)
}
#endif
