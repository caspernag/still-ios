import Charts
import DesignSystem
import StillKit
import SwiftUI

/// S2: Insights (Pro). The last 7 days of reclaimed time, streak, sessions and urges.
struct InsightsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let days = model.lastSevenDays
        let total = days.reduce(0) { $0 + $1.seconds }

        StillScreen(spacing: 20) {
            StillTopBar {
                CircleIconButton(systemImage: "chevron.left", accessibilityLabel: "Back") {
                    dismiss()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Last 7 days")
                    .stillFont(.footnoteEmphasized)
                    .fontWeight(.medium)
                    .foregroundStyle(StillColor.inkSecondary)
                Text(Formatters.duration(seconds: total))
                    .stillFont(.stat)
                    .foregroundStyle(StillColor.ink)
                Text("reclaimed")
                    .stillFont(.subheadline)
                    .foregroundStyle(StillColor.inkSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            StillCard {
                ReclaimedChart(days: days)
                    .frame(height: 200)
                    .padding(StillSpacing.rowHorizontal)
            }

            StatPairCard(
                leadingValue: Text(Formatters.streakDays(model.streak)),
                leadingLabel: Text("streak"),
                trailingValue: Text(verbatim: "\(model.sessionsLastSevenDays)"),
                trailingLabel: model.sessionsLastSevenDays == 1 ? Text("session") : Text("sessions")
            )

            StatPairCard(
                leadingValue: Text(verbatim: "\(model.urgesLastSevenDays)"),
                leadingLabel: Text(Formatters.urgesLabel(model.urgesLastSevenDays)),
                trailingValue: Text(Formatters.duration(seconds: average(days))),
                trailingLabel: Text("daily average")
            )

            Spacer(minLength: 8)
        }
    }

    private func average(_ days: [DayTotal]) -> TimeInterval {
        guard !days.isEmpty else { return 0 }
        return days.reduce(0) { $0 + $1.seconds } / Double(days.count)
    }
}

/// A calm bar chart of reclaimed minutes per day, with accent bars.
private struct ReclaimedChart: View {
    let days: [DayTotal]

    var body: some View {
        Chart(days) { day in
            BarMark(
                x: .value("Day", day.day, unit: .day),
                y: .value("Minutes", day.minutes),
                width: .ratio(0.55)
            )
            .foregroundStyle(StillColor.accent)
            .cornerRadius(6)
            .accessibilityLabel(Text(day.day, format: .dateTime.weekday(.wide)))
            .accessibilityValue(Text(Formatters.duration(minutes: day.minutes)))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                    .foregroundStyle(StillColor.inkSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(StillColor.divider)
                AxisValueLabel {
                    if let minutes = value.as(Int.self) {
                        Text(Formatters.duration(minutes: minutes))
                    }
                }
                .foregroundStyle(StillColor.inkSecondary)
            }
        }
        .chartYScale(domain: 0...max(30, (days.map(\.minutes).max() ?? 0)))
    }
}
