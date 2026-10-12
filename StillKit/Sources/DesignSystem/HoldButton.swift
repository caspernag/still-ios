#if os(iOS)
import SwiftUI

/// A secondary button that fills from left to right with peach while held.
/// It completes after `duration` seconds with a success haptic and resets if released early.
public struct HoldButton: View {
    let title: LocalizedStringKey
    let duration: Double
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isHolding = false
    @State private var completions = 0
    @State private var didComplete = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ title: LocalizedStringKey, duration: Double = 5, onComplete: @escaping () -> Void) {
        self.title = title
        self.duration = duration
        self.onComplete = onComplete
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: StillRadius.card, style: .continuous)
        Text(title)
            .stillFont(.button)
            .foregroundStyle(StillColor.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: StillSize.button)
            .background {
                SecondarySurface(isPressed: false)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Rectangle()
                                .fill(StillColor.accentSoft)
                                .frame(width: proxy.size.width * progress)
                        }
                        .clipShape(shape)
                    }
            }
            .contentShape(shape)
            .scaleEffect(isHolding ? 0.99 : 1)
            .onLongPressGesture(minimumDuration: duration, maximumDistance: 60) {
                complete()
            } onPressingChanged: { pressing in
                pressingChanged(pressing)
            }
            .sensoryFeedback(.success, trigger: completions)
            .sensoryFeedback(.impact(weight: .light), trigger: isHolding) { _, holding in holding }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("Touch and hold for \(Int(duration)) seconds."))
    }

    private func pressingChanged(_ pressing: Bool) {
        isHolding = pressing
        if pressing {
            didComplete = false
            progress = 0
            withAnimation(.linear(duration: duration)) { progress = 1 }
        } else if !didComplete {
            // Released early: reset.
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { progress = 0 }
        }
    }

    private func complete() {
        didComplete = true
        completions += 1
        isHolding = false
        onComplete()
        withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
    }
}
#endif
