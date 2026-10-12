#if os(iOS)
import SwiftUI

/// A card: surface fill, radius 14 and a 1 px border ring.
public struct StillCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: StillRadius.card, style: .continuous)
                    .fill(StillColor.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: StillRadius.card, style: .continuous)
                    .strokeBorder(StillColor.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: StillRadius.card, style: .continuous))
    }
}

/// An inset 1 px divider between grouped-list rows.
public struct StillDivider: View {
    let leadingInset: CGFloat

    public init(leadingInset: CGFloat = StillSpacing.rowHorizontal) {
        self.leadingInset = leadingInset
    }

    public var body: some View {
        Rectangle()
            .fill(StillColor.divider)
            .frame(height: 1)
            .padding(.leading, leadingInset)
            .accessibilityHidden(true)
    }
}

/// A grouped list: a card whose rows are separated by inset dividers.
public struct StillGroupedList<Row: Identifiable, RowContent: View>: View {
    let rows: [Row]
    let dividerInset: CGFloat
    let rowContent: (Row) -> RowContent

    public init(_ rows: [Row], dividerInset: CGFloat = StillSpacing.rowHorizontal, @ViewBuilder row: @escaping (Row) -> RowContent) {
        self.rows = rows
        self.dividerInset = dividerInset
        self.rowContent = row
    }

    public var body: some View {
        StillCard {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { StillDivider(leadingInset: dividerInset) }
                    rowContent(row)
                }
            }
        }
    }
}

/// An uppercase section header above a grouped list ("SUBSCRIPTION").
public struct StillSectionHeader: View {
    let title: LocalizedStringKey

    public init(_ title: LocalizedStringKey) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .textCase(.uppercase)
            .stillFont(.footnote)
            .foregroundStyle(StillColor.inkSecondary)
            .padding(.leading, StillSpacing.rowHorizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A peach tile with a number or a symbol (onboarding steps, paywall features).
public struct StillTile<Content: View>: View {
    let size: CGFloat
    let radius: CGFloat
    let fill: Color
    let content: Content

    public init(size: CGFloat = 30, radius: CGFloat = StillRadius.tile, fill: Color = StillColor.accentSoft, @ViewBuilder content: () -> Content) {
        self.size = size
        self.radius = radius
        self.fill = fill
        self.content = content()
    }

    public var body: some View {
        content
            .foregroundStyle(StillColor.ink)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .accessibilityHidden(true)
    }
}

/// A numbered step tile ("1", "2", "3").
public struct StepNumberTile: View {
    let number: Int
    let size: CGFloat
    let radius: CGFloat

    public init(_ number: Int, size: CGFloat = 30, radius: CGFloat = StillRadius.tile) {
        self.number = number
        self.size = size
        self.radius = radius
    }

    public var body: some View {
        StillTile(size: size, radius: radius) {
            Text(verbatim: "\(number)")
                .font(.system(size: size >= 30 ? 14 : 12, weight: .semibold))
        }
    }
}

/// A two-column stat card ("3 categories locked | 2 urges resisted").
public struct StatPairCard: View {
    let leadingValue: Text
    let leadingLabel: Text
    let trailingValue: Text
    let trailingLabel: Text

    public init(leadingValue: Text, leadingLabel: Text, trailingValue: Text, trailingLabel: Text) {
        self.leadingValue = leadingValue
        self.leadingLabel = leadingLabel
        self.trailingValue = trailingValue
        self.trailingLabel = trailingLabel
    }

    public var body: some View {
        StillCard {
            HStack(spacing: 0) {
                column(value: leadingValue, label: leadingLabel)
                Rectangle()
                    .fill(StillColor.divider)
                    .frame(width: 1)
                    .padding(.vertical, 12)
                column(value: trailingValue, label: trailingLabel)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func column(value: Text, label: Text) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            value
                .stillFont(.statValue)
                .foregroundStyle(StillColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            label
                .stillFont(.footnote)
                .foregroundStyle(StillColor.inkSecondary)
        }
        .padding(.horizontal, StillSpacing.rowHorizontal)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// The "Session on" pill with a live apricot dot.
public struct StatusPill: View {
    let title: LocalizedStringKey

    public init(_ title: LocalizedStringKey) {
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 7) {
            Circle().fill(StillColor.accent).frame(width: 6, height: 6)
            Text(title)
                .stillFont(.footnoteEmphasized)
                .foregroundStyle(StillColor.ink)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 30)
        .background(Capsule().fill(StillColor.accentSoft))
        .accessibilityElement(children: .combine)
    }
}

/// A small peach badge ("Best value").
public struct StillBadge: View {
    let title: LocalizedStringKey

    public init(_ title: LocalizedStringKey) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .stillFont(.captionEmphasized)
            .foregroundStyle(StillColor.ink)
            .padding(.horizontal, 9)
            .frame(minHeight: 24)
            .background(Capsule().fill(StillColor.accentSoft))
    }
}

/// Step indicator dots: the active step is a wide pill.
public struct StepDots: View {
    let count: Int
    let current: Int

    public init(count: Int, current: Int) {
        self.count = count
        self.current = current
    }

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? StillColor.ink : StillColor.neutral)
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(current + 1) of \(count)"))
    }
}
#endif
