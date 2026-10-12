import DesignSystem
import StillKit
import SwiftUI

/// Screen 1: "Your phone, quieter."
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var isRequesting = false

    var body: some View {
        StillScreen {
            StillTopBar {
                LogoLockup()
            } trailing: {
                StepDots(count: 2, current: 0)
            }

            Spacer(minLength: 12)

            VStack(alignment: .leading, spacing: 32) {
                Text("Your phone,\n\(quieter)")
                    .stillFont(.hero)
                    .foregroundStyle(StillColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                StillCard {
                    VStack(spacing: 0) {
                        step(1, "Pick the apps that pull you in.")
                        StillDivider(leadingInset: 60)
                        step(2, "Tap once. They stay locked until the timer ends.")
                        StillDivider(leadingInset: 60)
                        step(3, "Ending early takes a slow, deliberate hold.")
                    }
                }
            }

            Spacer(minLength: 12)

            VStack(spacing: StillSpacing.buttonGap) {
                Button {
                    Task {
                        isRequesting = true
                        await model.requestAuthorization()
                        isRequesting = false
                    }
                } label: {
                    Text("Allow Screen Time access")
                }
                .buttonStyle(.stillPrimary)
                .disabled(isRequesting)
                .accessibilityIdentifier("allowScreenTime")

                Text("Everything stays on your iPhone. Still never sees which apps you use.")
                    .stillFont(.footnote)
                    .foregroundStyle(StillColor.inkSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var quieter: Text {
        Text("quieter.").foregroundStyle(StillColor.accentText)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            StepNumberTile(number)
            Text(text)
                .stillFont(.callout)
                .foregroundStyle(StillColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, StillSpacing.rowHorizontal)
        .padding(.vertical, StillSpacing.rowVertical)
        .accessibilityElement(children: .combine)
    }
}
