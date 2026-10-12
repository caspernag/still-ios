import Foundation
import StillKit

/// Localized strings built from numbers. All text goes through the String Catalog;
/// "one" vs "other" is chosen here (English and Norwegian Bokmål both use those two forms).
enum Formatters {
    /// Short duration: "45 min", "2 h", "3 h 12 min".
    static func duration(seconds: TimeInterval) -> String {
        duration(style: DurationText.style(seconds: seconds))
    }

    static func duration(minutes: Int) -> String {
        duration(style: DurationText.style(minutes: minutes))
    }

    private static func duration(style: DurationText.Style) -> String {
        switch style {
        case .minutes(let m): String(localized: "\(m) min")
        case .hours(let h): String(localized: "\(h) h")
        case .hoursMinutes(let h, let m): String(localized: "\(h) h \(m) min")
        }
    }

    /// Long duration under the "Be still" title: "30 minutes", "1 hour", "1 h 45 min".
    static func longDuration(minutes: Int) -> String {
        switch DurationText.style(minutes: minutes) {
        case .minutes(let m):
            m == 1 ? String(localized: "\(m) minute") : String(localized: "\(m) minutes")
        case .hours(let h):
            h == 1 ? String(localized: "\(h) hour") : String(localized: "\(h) hours")
        case .hoursMinutes:
            duration(minutes: minutes)
        }
    }

    /// Segment titles: "15 min", "30 min", "1 hour", "2 hours".
    static func segmentTitle(minutes: Int) -> String {
        minutes < 60 ? duration(minutes: minutes) : longDuration(minutes: minutes)
    }

    /// "30 minutes" in the headline "30 minutes,\nreclaimed."
    static func reclaimedHeadline(minutes: Int) -> String {
        let amount = longDuration(minutes: minutes)
        return String(localized: "\(amount),\nreclaimed.")
    }

    static func streakDays(_ days: Int) -> String {
        days == 1 ? String(localized: "\(days) day") : String(localized: "\(days) days")
    }

    /// "reclaimed · 6 day streak"
    static func reclaimedStreakLine(streak: Int) -> String {
        streak > 0 ? String(localized: "reclaimed · \(streak) day streak") : String(localized: "reclaimed")
    }

    // MARK: Selection

    /// "3 categories", "1 app, 2 categories", "4 apps, 1 website".
    static func selectionCounts(_ summary: SelectionSummary) -> String {
        var parts: [String] = []
        if summary.applications > 0 {
            let n = summary.applications
            parts.append(n == 1 ? String(localized: "\(n) app") : String(localized: "\(n) apps"))
        }
        if summary.categories > 0 {
            let n = summary.categories
            parts.append(n == 1 ? String(localized: "\(n) category") : String(localized: "\(n) categories"))
        }
        if summary.webDomains > 0 {
            let n = summary.webDomains
            parts.append(n == 1 ? String(localized: "\(n) website") : String(localized: "\(n) websites"))
        }
        return parts.formatted(.list(type: .and, width: .narrow))
    }

    /// "Blocking 3 categories" / "Nothing selected yet"
    static func blockingTitle(_ summary: SelectionSummary) -> String {
        if summary.isEmpty { return String(localized: "Choose what to block") }
        let counts = selectionCounts(summary)
        return String(localized: "Blocking \(counts)")
    }

    /// The label under the number in the session stat card: "categories locked", "apps locked".
    static func lockedLabel(_ summary: SelectionSummary) -> String {
        let total = summary.total
        if summary.categories == total {
            return total == 1 ? String(localized: "category locked") : String(localized: "categories locked")
        }
        if summary.applications == total {
            return total == 1 ? String(localized: "app locked") : String(localized: "apps locked")
        }
        if summary.webDomains == total {
            return total == 1 ? String(localized: "website locked") : String(localized: "websites locked")
        }
        return String(localized: "apps & categories locked")
    }

    /// "3 categories locked", used in the Live Activity.
    static func lockedSummary(_ summary: SelectionSummary) -> String {
        let counts = selectionCounts(summary)
        return String(localized: "\(counts) locked")
    }

    static func urgesLabel(_ count: Int) -> String {
        count == 1 ? String(localized: "urge resisted") : String(localized: "urges resisted")
    }

    // MARK: Time

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func timeRange(start: TimeOfDay, end: TimeOfDay) -> String {
        let calendar = Calendar.current
        let reference = calendar.startOfDay(for: Date())
        let startDate = calendar.date(bySettingHour: start.hour, minute: start.minute, second: 0, of: reference) ?? reference
        let endDate = calendar.date(bySettingHour: end.hour, minute: end.minute, second: 0, of: reference) ?? reference
        return "\(time(startDate))–\(time(endDate))"
    }

    /// "Every day", "Weekdays", "Weekends" or "Mon, Wed, Fri".
    static func weekdays(_ days: Set<Weekday>) -> String {
        let all = Set(Weekday.allCases)
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        if days == all { return String(localized: "Every day") }
        if days == weekdays { return String(localized: "Weekdays") }
        if days == [.saturday, .sunday] { return String(localized: "Weekends") }
        let symbols = Calendar.current.shortWeekdaySymbols
        return Weekday.ordered(firstWeekday: Calendar.current.firstWeekday)
            .filter { days.contains($0) }
            .map { symbols[$0.rawValue - 1] }
            .joined(separator: ", ")
    }
}
