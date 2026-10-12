import DesignSystem
import StillKit
import SwiftUI

/// Screen 9: hours and minutes wheels (Pro). 15 minutes minimum, 12 hours maximum.
struct CustomDurationSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(AppClock.self) private var clock
    @Environment(\.dismiss) private var dismiss

    @State private var hours: Int
    @State private var minutes: Int

    private let minuteSteps = Array(stride(from: 0, through: 55, by: 5))

    init(initialMinutes: Int) {
        let clamped = SessionMath.clamp(minutes: initialMinutes)
        _hours = State(initialValue: clamped / 60)
        _minutes = State(initialValue: (clamped % 60) / 5 * 5)
    }

    /// The chosen total, clamped to 15 min ... 12 h.
    private var total: Int {
        SessionMath.clamp(minutes: hours * 60 + minutes)
    }

    private var endDate: Date {
        clock.now.addingTimeInterval(TimeInterval(total * 60))
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Custom duration")
                    .stillFont(.dialogTitle)
                    .foregroundStyle(StillColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                CloseButton { dismiss() }
                    .padding(.trailing, -6)
            }
            .padding(.top, 20)

            StillCard {
                HStack(spacing: 0) {
                    Picker(selection: $hours) {
                        ForEach(0...12, id: \.self) { h in
                            Text(h == 1 ? String(localized: "\(h) hour") : String(localized: "\(h) hours"))
                                .tag(h)
                        }
                    } label: {
                        Text("Hours")
                    }
                    .pickerStyle(.wheel)
                    .accessibilityIdentifier("hoursPicker")

                    Picker(selection: $minutes) {
                        ForEach(minuteSteps, id: \.self) { m in
                            Text("\(m) min").tag(m)
                        }
                    } label: {
                        Text("Minutes")
                    }
                    .pickerStyle(.wheel)
                    .accessibilityIdentifier("minutesPicker")
                }
                .frame(height: 200)
            }
            .onChange(of: hours) { _, newHours in
                if newHours == 12 { minutes = 0 }
            }
            .onChange(of: minutes) { _, newMinutes in
                // 12 hours is the maximum; the wheels never show more than will be set.
                if hours == 12 && newMinutes != 0 { minutes = 0 }
            }

            Group {
                if hours * 60 + minutes < StillConstants.minimumSessionMinutes {
                    Text("Sessions are at least 15 minutes.")
                } else {
                    Text("Ends at \(endDate, style: .time)")
                }
            }
            .stillFont(.footnote)
            .foregroundStyle(StillColor.inkSecondary)
            .frame(maxWidth: .infinity)

            Button {
                model.setCustomDuration(total)
            } label: {
                let amount = Formatters.duration(minutes: total)
                Text("Set \(amount)")
            }
            .buttonStyle(.stillPrimary)
            .accessibilityIdentifier("setDuration")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, StillSpacing.screen)
        .padding(.bottom, StillSpacing.bottom)
        .background(StillColor.background.ignoresSafeArea())
    }
}
