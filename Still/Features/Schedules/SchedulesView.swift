import DesignSystem
import StillKit
import SwiftUI

/// S1: Schedules (Pro). Each schedule locks the same apps automatically at set times.
struct SchedulesView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var editing: StillSchedule?

    var body: some View {
        StillScreen(spacing: 20) {
            StillTopBar {
                CircleIconButton(systemImage: "chevron.left", accessibilityLabel: "Back") {
                    dismiss()
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Schedules")
                    .stillFont(.title)
                    .foregroundStyle(StillColor.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Lock your apps automatically, every week.")
                    .stillFont(.subheadline)
                    .foregroundStyle(StillColor.inkSecondary)
            }

            if model.schedules.isEmpty {
                StillCard {
                    Text("No schedules yet.")
                        .stillFont(.callout)
                        .foregroundStyle(StillColor.inkSecondary)
                        .padding(StillSpacing.rowHorizontal)
                }
            } else {
                StillGroupedList(model.schedules) { schedule in
                    ScheduleRow(schedule: schedule) {
                        editing = schedule
                    }
                }
            }

            if !model.hasSelection {
                Text("Schedules lock the apps you chose on Home. Choose some apps first.")
                    .stillFont(.footnote)
                    .foregroundStyle(StillColor.inkSecondary)
            }

            Button {
                editing = StillSchedule(
                    name: "",
                    start: TimeOfDay(hour: 9, minute: 0),
                    end: TimeOfDay(hour: 17, minute: 0),
                    weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                    isEnabled: true
                )
            } label: {
                Label("Add schedule", systemImage: "plus")
            }
            .buttonStyle(.stillSecondary)
            .accessibilityIdentifier("addSchedule")

            Spacer(minLength: 8)

            Text("Schedules run on their own, even when Still is closed. Manual sessions and schedules never cancel each other.")
                .stillFont(.footnote)
                .foregroundStyle(StillColor.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .sheet(item: $editing) { schedule in
            ScheduleEditor(
                schedule: schedule,
                isNew: !model.schedules.contains { $0.id == schedule.id }
            )
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(StillRadius.sheet)
            .presentationBackground(StillColor.background)
        }
    }
}

private struct ScheduleRow: View {
    let schedule: StillSchedule
    let onEdit: () -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.name)
                        .stillFont(.calloutMedium)
                        .foregroundStyle(StillColor.ink)
                    Text(verbatim: "\(Formatters.timeRange(start: schedule.start, end: schedule.end)) · \(Formatters.weekdays(schedule.weekdays))")
                        .stillFont(.footnote)
                        .foregroundStyle(StillColor.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Edit schedule"))

            Toggle(isOn: Binding(
                get: { schedule.isEnabled },
                set: { model.setSchedule(schedule.id, enabled: $0) }
            )) {
                Text(schedule.name)
            }
            .labelsHidden()
            .stillToggleTint()
        }
        .padding(.horizontal, StillSpacing.rowHorizontal)
        .padding(.vertical, 12)
    }
}

/// Add / edit a schedule.
private struct ScheduleEditor: View {
    let isNew: Bool
    @State private var draft: StillSchedule
    @State private var startDate: Date
    @State private var endDate: Date
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    init(schedule: StillSchedule, isNew: Bool) {
        self.isNew = isNew
        _draft = State(initialValue: schedule)
        _startDate = State(initialValue: Self.date(from: schedule.start))
        _endDate = State(initialValue: Self.date(from: schedule.end))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    (isNew ? Text("New schedule") : Text("Edit schedule"))
                        .stillFont(.dialogTitle)
                        .foregroundStyle(StillColor.ink)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    CloseButton { dismiss() }
                        .padding(.trailing, -6)
                }
                .padding(.top, 20)

                StillCard {
                    VStack(spacing: 0) {
                        TextField(text: $draft.name, prompt: Text("Name, e.g. Mornings")) {
                            Text("Name")
                        }
                        .stillFont(.callout)
                        .foregroundStyle(StillColor.ink)
                        .padding(.horizontal, StillSpacing.rowHorizontal)
                        .frame(minHeight: 50)
                        .accessibilityIdentifier("scheduleName")

                        StillDivider()
                        DatePicker(selection: $startDate, displayedComponents: .hourAndMinute) {
                            Text("Starts")
                                .stillFont(.callout)
                                .foregroundStyle(StillColor.ink)
                        }
                        .padding(.horizontal, StillSpacing.rowHorizontal)
                        .frame(minHeight: 50)

                        StillDivider()
                        DatePicker(selection: $endDate, displayedComponents: .hourAndMinute) {
                            Text("Ends")
                                .stillFont(.callout)
                                .foregroundStyle(StillColor.ink)
                        }
                        .padding(.horizontal, StillSpacing.rowHorizontal)
                        .frame(minHeight: 50)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    StillSectionHeader("Repeat")
                    WeekdayPicker(selection: $draft.weekdays)
                }

                if let message = validationMessage {
                    Text(message)
                        .stillFont(.footnote)
                        .foregroundStyle(StillColor.accentText)
                }

                Button {
                    save()
                } label: {
                    Text("Save")
                }
                .buttonStyle(.stillPrimary)
                .disabled(validationMessage != nil)
                .accessibilityIdentifier("saveSchedule")

                if !isNew {
                    Button(role: .destructive) {
                        model.deleteSchedule(draft.id)
                        dismiss()
                    } label: {
                        Text("Delete schedule")
                            .stillFont(.callout)
                            .foregroundStyle(StillColor.accentText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, StillSpacing.screen)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(StillColor.background.ignoresSafeArea())
    }

    private var current: StillSchedule {
        var schedule = draft
        schedule.name = schedule.name.trimmingCharacters(in: .whitespacesAndNewlines)
        schedule.start = Self.timeOfDay(from: startDate)
        schedule.end = Self.timeOfDay(from: endDate)
        return schedule
    }

    private var validationMessage: String? {
        switch ScheduleMapping.validate(current) {
        case .emptyName?: String(localized: "Give the schedule a name.")
        case .noWeekdays?: String(localized: "Pick at least one day.")
        case .tooShort?: String(localized: "Schedules are at least 15 minutes.")
        case nil: nil
        }
    }

    private func save() {
        model.upsertSchedule(current)
        dismiss()
    }

    private static func date(from time: TimeOfDay) -> Date {
        Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Date()) ?? Date()
    }

    private static func timeOfDay(from date: Date) -> TimeOfDay {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return TimeOfDay(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }
}

/// Seven round day toggles, starting on the locale's first weekday.
private struct WeekdayPicker: View {
    @Binding var selection: Set<Weekday>

    var body: some View {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let names = calendar.standaloneWeekdaySymbols
        HStack(spacing: 6) {
            ForEach(Weekday.ordered(firstWeekday: calendar.firstWeekday), id: \.self) { day in
                let isOn = selection.contains(day)
                Button {
                    if isOn { selection.remove(day) } else { selection.insert(day) }
                } label: {
                    Text(verbatim: symbols[day.rawValue - 1])
                        .stillFont(.footnoteEmphasized)
                        .foregroundStyle(StillColor.ink)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Circle().fill(isOn ? StillColor.accentSoft : StillColor.surface))
                        .overlay(Circle().strokeBorder(isOn ? StillColor.accent : StillColor.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: names[day.rawValue - 1]))
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}
