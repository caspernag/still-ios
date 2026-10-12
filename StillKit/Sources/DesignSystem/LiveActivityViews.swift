#if os(iOS)
import SwiftUI

/// Views for the session Live Activity. They live here (not in the widget target)
/// so the app can render the same views in demo mode for App Store screenshots.
///
/// Countdowns use `Text(timerInterval:)` and `ProgressView(timerInterval:)`, which the
/// system animates on its own, so the activity never needs updates while it runs.
public enum LiveActivityViews {
    /// The small outlined logo used in the Dynamic Island.
    public struct IslandMark: View {
        let size: CGFloat
        public init(size: CGFloat = 16) { self.size = size }

        public var body: some View {
            Circle()
                .strokeBorder(StillColor.Island.text, lineWidth: 1.5)
                .frame(width: size, height: size)
                .overlay(Circle().fill(StillColor.accent).frame(width: size * 0.32, height: size * 0.32))
                .accessibilityHidden(true)
        }
    }

    /// Lock Screen / banner presentation.
    public struct LockScreen: View {
        let start: Date
        let end: Date
        let isComplete: Bool
        let summary: String

        public init(start: Date, end: Date, isComplete: Bool, summary: String) {
            self.start = start
            self.end = end
            self.isComplete = isComplete
            self.summary = summary
        }

        public var body: some View {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    if isComplete {
                        Circle().strokeBorder(StillColor.success, lineWidth: 4)
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(StillColor.success)
                    } else {
                        ProgressView(timerInterval: start...max(start, end), countsDown: true) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                        .progressViewStyle(.circular)
                        .tint(StillColor.accent)
                        .frame(width: 52, height: 52)
                        Circle().fill(StillColor.logo).frame(width: 8, height: 8)
                    }
                }
                .frame(width: 52, height: 52)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    if isComplete {
                        Text("Session complete")
                            .font(.system(size: 13))
                            .foregroundStyle(StillColor.inkSecondary)
                        Text("Your apps are back.")
                            .font(.system(size: 22, weight: .semibold))
                            .tracking(-0.5)
                            .foregroundStyle(StillColor.ink)
                    } else {
                        Text(verbatim: "Still · \(summary)")
                            .font(.system(size: 13))
                            .foregroundStyle(StillColor.inkSecondary)
                            .lineLimit(1)
                        Text(timerInterval: start...max(start, end), countsDown: true)
                            .font(.system(size: 30, weight: .semibold).monospacedDigit())
                            .tracking(-0.9)
                            .foregroundStyle(StillColor.ink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isComplete {
                    Text("ends \(end, style: .time)")
                        .font(.system(size: 13))
                        .foregroundStyle(StillColor.inkSecondary)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 4)
                }
            }
            .padding(16)
        }
    }

    /// Dynamic Island, compact leading.
    public struct CompactLeading: View {
        public init() {}
        public var body: some View { IslandMark(size: 16) }
    }

    /// Dynamic Island, compact trailing: the countdown.
    public struct CompactTrailing: View {
        let start: Date
        let end: Date
        let isComplete: Bool

        public init(start: Date, end: Date, isComplete: Bool) {
            self.start = start
            self.end = end
            self.isComplete = isComplete
        }

        public var body: some View {
            Group {
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(StillColor.success)
                } else {
                    Text(timerInterval: start...max(start, end), countsDown: true)
                        .font(.system(size: 14, weight: .semibold).monospacedDigit())
                        .foregroundStyle(StillColor.Island.text)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 52)
                }
            }
        }
    }

    /// Dynamic Island, minimal.
    public struct Minimal: View {
        let isComplete: Bool
        public init(isComplete: Bool) { self.isComplete = isComplete }

        public var body: some View {
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(StillColor.success)
            } else {
                IslandMark(size: 16)
            }
        }
    }

    /// Dynamic Island expanded, leading region: logo and name.
    public struct ExpandedLeading: View {
        public init() {}
        public var body: some View {
            HStack(spacing: 8) {
                IslandMark(size: 18)
                Text(verbatim: "Still")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(StillColor.Island.text)
            }
            .padding(.leading, 6)
        }
    }

    /// Dynamic Island expanded, trailing region: the end time.
    public struct ExpandedTrailing: View {
        let end: Date
        let isComplete: Bool

        public init(end: Date, isComplete: Bool) {
            self.end = end
            self.isComplete = isComplete
        }

        public var body: some View {
            Group {
                if isComplete {
                    Text("Done")
                } else {
                    Text("ends \(end, style: .time)")
                }
            }
            .font(.system(size: 13))
            .foregroundStyle(StillColor.Island.secondary)
            .padding(.trailing, 6)
        }
    }

    /// Dynamic Island expanded, bottom region: big countdown and progress bar.
    public struct ExpandedBottom: View {
        let start: Date
        let end: Date
        let isComplete: Bool

        public init(start: Date, end: Date, isComplete: Bool) {
            self.start = start
            self.end = end
            self.isComplete = isComplete
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                if isComplete {
                    Text("Session complete")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(StillColor.Island.text)
                } else {
                    Text(timerInterval: start...max(start, end), countsDown: true)
                        .font(.system(size: 40, weight: .light).monospacedDigit())
                        .tracking(-1.6)
                        .foregroundStyle(StillColor.Island.text)
                    ProgressView(timerInterval: start...max(start, end), countsDown: true) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear)
                    .tint(StillColor.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.bottom, 4)
        }
    }
}
#endif
