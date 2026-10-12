import DesignSystem
import StillKit
import SwiftUI
import UIKit

/// Screen 11: shown when Screen Time access is denied or revoked.
struct NoAccessView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var isRequesting = false

    var body: some View {
        StillScreen {
            StillTopBar {
                LogoLockup()
            }

            Spacer(minLength: 12)

            VStack(spacing: 24) {
                HaloEmblem(diameter: 84, halo: 8, fill: StillColor.surface, castsShadow: false) {
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(StillColor.inkSecondary)
                }

                VStack(spacing: 8) {
                    Text("Still needs Screen Time access")
                        .stillFont(.title2)
                        .foregroundStyle(StillColor.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("It's how Still locks apps for you. Nothing about your usage leaves this iPhone.")
                        .stillFont(.subheadline)
                        .foregroundStyle(StillColor.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                .frame(maxWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 12)

            StillCard {
                VStack(spacing: 0) {
                    step(1, "Open Settings → Screen Time")
                    StillDivider(leadingInset: 52)
                    step(2, "Allow Still under Apps with Access")
                }
            }

            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Text("Open Settings")
                }
                .buttonStyle(.stillPrimary)
                .accessibilityIdentifier("openSettings")

                Button {
                    Task {
                        isRequesting = true
                        await model.requestAuthorization()
                        isRequesting = false
                    }
                } label: {
                    Text("Try again")
                }
                .buttonStyle(.stillSecondary)
                .disabled(isRequesting)
                .accessibilityIdentifier("tryAgain")
            }
        }
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            StillTile(size: 24, radius: 12) {
                Text(verbatim: "\(number)")
                    .font(.system(size: 12, weight: .semibold))
            }
            Text(text)
                .stillFont(.subheadline)
                .foregroundStyle(StillColor.ink)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, StillSpacing.rowHorizontal)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
