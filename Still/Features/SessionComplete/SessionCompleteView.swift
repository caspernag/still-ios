import DesignSystem
import StillKit
import StoreKit
import SwiftUI

/// Screen 7: "30 minutes, reclaimed."
struct SessionCompleteView: View {
    let record: SessionRecord

    @Environment(AppModel.self) private var model
    @Environment(\.requestReview) private var requestReview
    @State private var appeared = false

    var body: some View {
        StillScreen {
            StillTopBar {
                LogoLockup()
            }

            Spacer(minLength: 16)

            VStack(spacing: 28) {
                CompleteCircle(appeared: appeared)

                VStack(spacing: 8) {
                    Text(Formatters.reclaimedHeadline(minutes: record.reclaimedMinutes))
                        .stillFont(.title)
                        .foregroundStyle(StillColor.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("completeHeadline")
                    Text("Your apps are back. Use them on purpose.")
                        .stillFont(.subheadline)
                        .foregroundStyle(StillColor.inkSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 16)

            StatPairCard(
                leadingValue: Text(Formatters.streakDays(model.streak)),
                leadingLabel: Text("streak"),
                trailingValue: Text(Formatters.duration(seconds: model.thisWeekSeconds)),
                trailingLabel: Text("this week")
            )

            VStack(spacing: 10) {
                Button {
                    model.dismissCompletion(goAgain: false)
                } label: {
                    Text("Done")
                }
                .buttonStyle(.stillPrimary)
                .accessibilityIdentifier("completeDone")

                Button {
                    model.dismissCompletion(goAgain: true)
                } label: {
                    Text("Go again")
                }
                .buttonStyle(.stillSecondary)
                .accessibilityIdentifier("goAgain")
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.1)) { appeared = true }
            if model.completionAppeared() {
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    requestReview()
                }
            }
        }
    }
}

/// The success-soft circle with a green ring and check.
private struct CompleteCircle: View {
    let appeared: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(StillColor.successSoft.shadow(.inner(color: .black.opacity(0.04), radius: 3, x: 0, y: -2)))
                .overlay(Circle().strokeBorder(StillColor.border, lineWidth: 1).padding(-1))
                .shadow(color: StillColor.shadow.opacity(0.22), radius: 30, x: 0, y: 30)
            Circle()
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(StillColor.success.opacity(0.84), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(14)
            CheckShape()
                .trim(from: 0, to: appeared ? 1 : 0)
                .stroke(StillColor.success, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: 200, height: 200)
        }
        .frame(width: StillSize.completeCircle, height: StillSize.completeCircle)
        .accessibilityHidden(true)
    }
}

/// The check mark from the design (M78 101 l15 15 30-32 in a 200 pt box).
private struct CheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 200
        var path = Path()
        path.move(to: CGPoint(x: 78 * scale, y: 101 * scale))
        path.addLine(to: CGPoint(x: 93 * scale, y: 116 * scale))
        path.addLine(to: CGPoint(x: 123 * scale, y: 84 * scale))
        return path
    }
}
