import DesignSystem
import FamilyControls
import ManagedSettings
import StillKit
import SwiftUI

/// Screen 3: "What pulls you in?"
///
/// iOS doesn't let apps list installed apps, so the design's toggle list becomes a
/// summary of the current selection plus Apple's FamilyActivityPicker.
struct ChooseAppsView: View {
    let isOnboarding: Bool

    @Environment(AppModel.self) private var model
    @State private var isPickerPresented = false
    @State private var draft = FamilyActivitySelection(includeEntireCategory: true)

    var body: some View {
        StillScreen {
            StillTopBar {
                if isOnboarding {
                    LogoLockup()
                } else {
                    CircleIconButton(systemImage: "chevron.left", accessibilityLabel: "Back") {
                        model.cancelChoosingApps()
                    }
                }
            } trailing: {
                if isOnboarding {
                    StepDots(count: 2, current: 1)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("What pulls you in?")
                    .stillFont(.title)
                    .foregroundStyle(StillColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Lock whole categories or single apps.")
                    .stillFont(.subheadline)
                    .foregroundStyle(StillColor.inkSecondary)
            }

            SelectionSummaryCard()

            Button {
                openPicker()
            } label: {
                model.hasSelection ? Text("Change apps") : Text("Choose apps")
            }
            .buttonStyle(.stillSecondary)
            .accessibilityIdentifier("chooseAppsButton")

            Spacer(minLength: 12)

            VStack(spacing: StillSpacing.buttonGap) {
                Text("Phone and Messages always work")
                    .stillFont(.footnote)
                    .foregroundStyle(StillColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button {
                    model.finishChoosingApps()
                } label: {
                    Text("Done")
                }
                .buttonStyle(.stillPrimary)
                .disabled(isOnboarding && !model.hasSelection)
                .accessibilityIdentifier("doneButton")
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $draft)
        .onChange(of: isPickerPresented) { _, presented in
            if !presented {
                model.saveSelection(draft)
            }
        }
    }

    private func openPicker() {
        #if DEBUG
        if model.config.isDemo {
            model.toggleDemoSelection()
            return
        }
        #endif
        draft = model.selection
        isPickerPresented = true
    }
}

/// Renders what is selected with `Label(token)`, the only way iOS exposes app names and icons.
struct SelectionSummaryCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        StillCard {
            VStack(alignment: .leading, spacing: 0) {
                if model.hasSelection {
                    HStack(spacing: 14) {
                        StillTile(size: 32) {
                            Image(systemName: "lock")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(Formatters.blockingTitle(model.selectionSummary))
                                .stillFont(.calloutMedium)
                                .foregroundStyle(StillColor.ink)
                            Text("Locked during every session")
                                .stillFont(.footnote)
                                .foregroundStyle(StillColor.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, StillSpacing.rowHorizontal)
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)

                    tokenRows
                } else {
                    Text("Nothing selected yet. Choose the apps, categories or websites you want to lock.")
                        .stillFont(.callout)
                        .foregroundStyle(StillColor.inkSecondary)
                        .padding(.horizontal, StillSpacing.rowHorizontal)
                        .padding(.vertical, 18)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityIdentifier("selectionSummary")
    }

    @ViewBuilder
    private var tokenRows: some View {
        #if DEBUG
        if model.config.isDemo {
            ForEach(["Social", "Video", "News"], id: \.self) { name in
                StillDivider(leadingInset: 62)
                row { Label(LocalizedStringKey(name), systemImage: "square.grid.2x2") }
            }
        } else {
            realTokenRows
        }
        #else
        realTokenRows
        #endif
    }

    @ViewBuilder
    private var realTokenRows: some View {
        let selection = model.selection
        let categories = Array(selection.categoryTokens).prefix(6)
        let apps = Array(selection.applicationTokens).prefix(max(0, 6 - categories.count))
        let domains = Array(selection.webDomainTokens).prefix(max(0, 6 - categories.count - apps.count))

        ForEach(Array(categories), id: \.self) { token in
            StillDivider(leadingInset: 62)
            row { Label(token) }
        }
        ForEach(Array(apps), id: \.self) { token in
            StillDivider(leadingInset: 62)
            row { Label(token) }
        }
        ForEach(Array(domains), id: \.self) { token in
            StillDivider(leadingInset: 62)
            row { Label(token) }
        }
        let shown = categories.count + apps.count + domains.count
        if model.selectionSummary.total > shown {
            StillDivider(leadingInset: 62)
            Text("and \(model.selectionSummary.total - shown) more")
                .stillFont(.footnote)
                .foregroundStyle(StillColor.inkSecondary)
                .padding(.leading, 62)
                .padding(.vertical, 12)
        }
    }

    private func row<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .stillFont(.callout)
            .foregroundStyle(StillColor.ink)
            .lineLimit(1)
            .padding(.leading, 62)
            .padding(.trailing, StillSpacing.rowHorizontal)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}
