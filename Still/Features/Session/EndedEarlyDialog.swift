import DesignSystem
import StillKit
import SwiftUI

/// Screen 8: the calm "Session ended" dialog. No shame copy.
struct EndedEarlyDialog: View {
    let record: SessionRecord
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            StillColor.scrim
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Circle()
                    .fill(StillColor.accentSoft)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "clock")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(StillColor.ink)
                    )
                    .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text("Session ended")
                        .stillFont(.dialogTitle)
                        .foregroundStyle(StillColor.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(message)
                        .stillFont(.subheadline)
                        .foregroundStyle(StillColor.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("endedEarlyMessage")
                }

                VStack(spacing: 8) {
                    Button {
                        model.dismissEndedEarly(startNew: false)
                    } label: {
                        Text("OK")
                    }
                    .buttonStyle(PrimaryButtonStyle(height: StillSize.dialogButton, radius: 13, font: .calloutMedium))
                    .accessibilityIdentifier("endedEarlyOK")

                    Button {
                        model.dismissEndedEarly(startNew: true)
                    } label: {
                        Text("Start a new session")
                    }
                    .buttonStyle(SecondaryButtonStyle(height: StillSize.dialogButton, radius: 13, font: .calloutMedium))
                    .accessibilityIdentifier("endedEarlyStartNew")
                }
            }
            .padding(EdgeInsets(top: 26, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: 290)
            .background {
                RoundedRectangle(cornerRadius: StillRadius.dialog, style: .continuous)
                    .fill(StillColor.surface)
                    .shadow(color: StillColor.shadow.opacity(0.4), radius: 30, x: 0, y: 30)
            }
            .padding(.horizontal, 30)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }

    private var message: String {
        let minutes = record.reclaimedMinutes
        if minutes < 1 {
            return String(localized: "You took a pause. That still counts.")
        }
        let amount = minutes == 1 ? String(localized: "\(minutes) minute") : String(localized: "\(minutes) minutes")
        return String(localized: "You stayed still for \(amount). That still counts.")
    }
}
