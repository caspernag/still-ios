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

/// What is selected: the count, then the real app and category icons (`Label(token)`).
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
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Locked during every session")
                                .stillFont(.footnote)
                                .foregroundStyle(StillColor.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, StillSpacing.rowHorizontal)
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)

                    StillDivider()

                    SelectionIcons(limit: 8)
                        .padding(.horizontal, StillSpacing.rowHorizontal)
                        .padding(.vertical, 14)
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
}
