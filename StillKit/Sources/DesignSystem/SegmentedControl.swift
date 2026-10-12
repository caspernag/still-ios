#if os(iOS)
import SwiftUI

/// A segmented control in the iOS style from the design: a fill track (radius 10,
/// 2 pt padding) with a white selected pill and a soft shadow.
public struct StillSegmentedControl<Value: Hashable>: View {
    public struct Option: Identifiable {
        public var value: Value
        public var title: Text
        public var accessibilityIdentifier: String
        public var id: Value { value }

        public init(value: Value, title: Text, accessibilityIdentifier: String) {
            self.value = value
            self.title = title
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    let options: [Option]
    let selection: Value?
    let onSelect: (Value) -> Void
    @Namespace private var namespace

    /// `selection` may be nil when nothing is selected (e.g. a custom duration).
    public init(options: [Option], selection: Value?, onSelect: @escaping (Value) -> Void) {
        self.options = options
        self.selection = selection
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(options) { option in
                let isSelected = option.value == selection
                Button {
                    onSelect(option.value)
                } label: {
                    option.title
                        .stillFont(isSelected ? .segmentSelected : .segment)
                        .foregroundStyle(StillColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: StillRadius.segment, style: .continuous)
                                    .fill(StillColor.surface)
                                    .shadow(color: .black.opacity(0.04), radius: 0, x: 0, y: 0)
                                    .shadow(color: .black.opacity(0.10), radius: 4, x: 0, y: 3)
                                    .shadow(color: .black.opacity(0.03), radius: 0.5, x: 0, y: 3)
                                    .matchedGeometryEffect(id: "pill", in: namespace)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityIdentifier(option.accessibilityIdentifier)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: StillRadius.control, style: .continuous).fill(StillColor.fill))
        .animation(.snappy(duration: 0.25), value: selection)
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// A native Toggle tinted with the accent color.
extension View {
    public func stillToggleTint() -> some View {
        tint(StillColor.accent)
    }
}
#endif
