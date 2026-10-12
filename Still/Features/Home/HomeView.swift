import DesignSystem
import FamilyControls
import ManagedSettings
import StillKit
import SwiftUI

/// Screen 2: Home.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(Entitlements.self) private var entitlements

    /// The fifth segment, for a custom duration (Pro).
    private static let customSegment = -1

    var body: some View {
        StillScreen {
            StillTopBar {
                LogoLockup()
            } trailing: {
                CircleIconButton(systemImage: "slider.horizontal.3", accessibilityLabel: "Settings") {
                    model.openSettings()
                }
                .accessibilityIdentifier("settingsButton")
            }

            Button {
                model.openInsights()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This week")
                        .stillFont(.footnoteEmphasized)
                        .fontWeight(.medium)
                        .foregroundStyle(StillColor.inkSecondary)
                    Text(Formatters.duration(seconds: model.thisWeekSeconds))
                        .stillFont(.stat)
                        .foregroundStyle(StillColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .contentTransition(.numericText())
                    Text(Formatters.reclaimedStreakLine(streak: model.streak))
                        .stillFont(.subheadline)
                        .foregroundStyle(StillColor.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Shows your weekly insights."))
            .accessibilityIdentifier("weekStat")

            Spacer(minLength: 24)

            BigCircleButton(
                title: "Be still",
                subtitle: Text(Formatters.longDuration(minutes: model.effectiveDurationMinutes))
            ) {
                model.startSession()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, StillSize.halo)
            .accessibilityIdentifier("bigCircle")

            Spacer(minLength: 24)

            StillSegmentedControl(
                options: segmentOptions,
                selection: selectedSegment
            ) { value in
                if value == Self.customSegment {
                    model.tapCustomDuration()
                } else {
                    model.selectPreset(value)
                }
            }

            BlockingCard()

            Button {
                model.startSession()
            } label: {
                Text("Start session")
            }
            .buttonStyle(.stillPrimary)
            .accessibilityIdentifier("startSession")
        }
    }

    private var segmentOptions: [StillSegmentedControl<Int>.Option] {
        var options = StillConstants.presetMinutes.map { minutes in
            StillSegmentedControl<Int>.Option(
                value: minutes,
                title: Text(Formatters.segmentTitle(minutes: minutes)),
                accessibilityIdentifier: "duration.\(minutes)"
            )
        }
        let isCustom = ProAccess.requiresPro(durationMinutes: model.effectiveDurationMinutes)
        options.append(.init(
            value: Self.customSegment,
            title: isCustom ? Text(Formatters.duration(minutes: model.effectiveDurationMinutes)) : Text("Custom"),
            accessibilityIdentifier: "duration.custom"
        ))
        return options
    }

    private var selectedSegment: Int {
        let minutes = model.effectiveDurationMinutes
        return StillConstants.presetMinutes.contains(minutes) ? minutes : Self.customSegment
    }
}

/// "Blocking 3 categories" card; opens Choose apps.
private struct BlockingCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button {
            model.openChooseApps()
        } label: {
            StillCard {
                HStack(spacing: 14) {
                    StillTile(size: 32) {
                        Image(systemName: "lock")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Formatters.blockingTitle(model.selectionSummary))
                            .stillFont(.calloutMedium)
                            .foregroundStyle(StillColor.ink)
                            .lineLimit(1)
                        subtitle
                            .stillFont(.footnote)
                            .foregroundStyle(StillColor.inkSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(StillColor.inkMuted)
                }
                .padding(.horizontal, StillSpacing.rowHorizontal)
                .padding(.vertical, 12)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("blockingCard")
    }

    @ViewBuilder
    private var subtitle: some View {
        if !model.hasSelection {
            Text("Tap to pick apps and categories")
        } else if model.config.isDemo {
            Text(verbatim: "Social, Video, News")
        } else {
            TokenNames(selection: model.selection)
        }
    }
}

/// Up to three selected items as titles, e.g. "Social, Video, News".
private struct TokenNames: View {
    let selection: FamilyActivitySelection

    var body: some View {
        HStack(spacing: 0) {
            let categories = Array(selection.categoryTokens.prefix(3))
            let apps = Array(selection.applicationTokens.prefix(max(0, 3 - categories.count)))
            ForEach(Array(categories.enumerated()), id: \.offset) { index, token in
                if index > 0 { Text(verbatim: ", ") }
                Label(token).labelStyle(.titleOnly)
            }
            ForEach(Array(apps.enumerated()), id: \.offset) { index, token in
                if index > 0 || !categories.isEmpty { Text(verbatim: ", ") }
                Label(token).labelStyle(.titleOnly)
            }
        }
    }
}
