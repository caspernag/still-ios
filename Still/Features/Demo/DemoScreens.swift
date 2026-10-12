#if DEBUG
import DesignSystem
import StillKit
import SwiftUI

/// Demo-only full-screen previews used for App Store screenshots: the shield and
/// the Live Activity can't be captured from a UI test, so the app renders the same
/// views in-app. Never compiled into Release builds.
struct DemoScreenOverlay: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.config.initialScreen {
        case .shield?:
            ShieldPreview()
        case .liveActivity?:
            LiveActivityPreview()
        default:
            EmptyView()
        }
    }
}

/// Mirrors what the ShieldConfiguration extension shows.
private struct ShieldPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            VStack(spacing: 28) {
                LogoEmblem(diameter: 96, dot: 20, halo: 10)
                VStack(spacing: 10) {
                    Text("Be still.")
                        .stillFont(.stat)
                        .foregroundStyle(StillColor.ink)
                    Text(verbatim: shieldSubtitle)
                        .stillFont(.body)
                        .foregroundStyle(StillColor.inkSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
            }
            Spacer()
            Button {} label: { Text("Close") }
                .buttonStyle(.stillPrimary)
            Text(verbatim: footnote)
                .stillFont(.footnote)
                .foregroundStyle(StillColor.inkSecondary)
        }
        .padding(.horizontal, StillSpacing.screen)
        .padding(.bottom, StillSpacing.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(StillColor.background.ignoresSafeArea())
    }

    private var footnote: String {
        let start = Formatters.time(Date().addingTimeInterval(-360))
        return String(localized: "You chose this at \(start).")
    }

    private var shieldSubtitle: String {
        let time = Formatters.time(Date().addingTimeInterval(24 * 60))
        return String(localized: "This app can wait. Your session ends at \(time).")
    }
}

/// A Lock Screen backdrop with the Live Activity banner and the Dynamic Island states.
private struct LiveActivityPreview: View {
    private let start = Date().addingTimeInterval(-342)
    private let end = Date().addingTimeInterval(24 * 60 + 18)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(uiColor: UIColor(hex: 0xE9D9CF)), Color(uiColor: UIColor(hex: 0xB9C2CC))],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 40)
                Text(Date(), format: .dateTime.hour().minute())
                    .font(.system(size: 92, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()

                // Dynamic Island, expanded.
                VStack(spacing: 14) {
                    HStack {
                        LiveActivityViews.ExpandedLeading()
                        Spacer()
                        LiveActivityViews.ExpandedTrailing(end: end, isComplete: false)
                    }
                    LiveActivityViews.ExpandedBottom(start: start, end: end, isComplete: false)
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 18)
                .background(RoundedRectangle(cornerRadius: 44, style: .continuous).fill(.black))

                // Lock Screen banner.
                LiveActivityViews.LockScreen(
                    start: start,
                    end: end,
                    isComplete: false,
                    summary: Formatters.lockedSummary(SelectionSummary(categories: 3))
                )
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(StillColor.surface.opacity(0.88)))
                .environment(\.colorScheme, .light)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 40)
        }
    }
}
#endif
