#if os(iOS)
import SwiftUI

/// The logo mark: an ink circle with an apricot dot.
public struct LogoMark: View {
    let diameter: CGFloat
    let dot: CGFloat

    public init(diameter: CGFloat = 24, dot: CGFloat = 7) {
        self.diameter = diameter
        self.dot = dot
    }

    public var body: some View {
        Circle()
            .fill(StillColor.logo)
            .frame(width: diameter, height: diameter)
            .overlay(Circle().fill(StillColor.accent).frame(width: dot, height: dot))
            .accessibilityHidden(true)
    }
}

/// The logo mark followed by the "Still" wordmark.
public struct LogoLockup: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 9) {
            LogoMark()
            Text(verbatim: "Still")
                .stillFont(.button)
                .tracking(-0.34)
                .foregroundStyle(StillColor.ink)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Still"))
        .accessibilityAddTraits(.isHeader)
    }
}

/// A large round emblem with a 1 px ring, a halo and a soft long shadow
/// (shield, paywall, no-access screens).
public struct HaloEmblem<Content: View>: View {
    let diameter: CGFloat
    let halo: CGFloat
    let fill: Color
    let castsShadow: Bool
    let content: Content

    public init(
        diameter: CGFloat,
        halo: CGFloat = StillSize.halo,
        fill: Color,
        castsShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.diameter = diameter
        self.halo = halo
        self.fill = fill
        self.castsShadow = castsShadow
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Circle().fill(StillColor.divider).frame(width: diameter + 2 * halo, height: diameter + 2 * halo)
            Circle().fill(StillColor.border).frame(width: diameter + 2, height: diameter + 2)
            Circle()
                .fill(fill.shadow(.inner(color: .black.opacity(0.04), radius: 3, x: 0, y: -2)))
                .frame(width: diameter, height: diameter)
            content
        }
        .shadow(color: StillColor.shadow.opacity(castsShadow ? 0.18 : 0), radius: 20, x: 0, y: 20)
        .accessibilityHidden(true)
    }
}

/// The logo mark as a large emblem (shield, paywall).
public struct LogoEmblem: View {
    let diameter: CGFloat
    let dot: CGFloat
    let halo: CGFloat

    public init(diameter: CGFloat = 96, dot: CGFloat = 20, halo: CGFloat = 10) {
        self.diameter = diameter
        self.dot = dot
        self.halo = halo
    }

    public var body: some View {
        HaloEmblem(diameter: diameter, halo: halo, fill: StillColor.logo) {
            Circle().fill(StillColor.accent).frame(width: dot, height: dot)
        }
    }
}

/// The 240 pt "Be still" circle button: peach fill, 1 px ring, 10 pt halo and a long soft shadow.
public struct BigCircleButton: View {
    let title: LocalizedStringKey
    let subtitle: Text
    let action: () -> Void

    public init(title: LocalizedStringKey, subtitle: Text, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Circle().fill(StillColor.accent).frame(width: 10, height: 10)
                Text(title)
                    .stillFont(.circleTitle)
                    .foregroundStyle(StillColor.ink)
                subtitle
                    .stillFont(.subheadline)
                    .foregroundStyle(StillColor.inkSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(24)
            .frame(width: StillSize.bigCircle, height: StillSize.bigCircle)
        }
        .buttonStyle(BigCircleStyle())
    }
}

private struct BigCircleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    Circle()
                        .fill(StillColor.divider)
                        .padding(-(StillSize.halo + 1))
                    Circle()
                        .fill(StillColor.border)
                        .padding(-1)
                    Circle()
                        .fill(StillColor.accentSoft.shadow(.inner(color: .black.opacity(0.04), radius: 3, x: 0, y: -2)))
                }
                .shadow(color: StillColor.shadow.opacity(0.22), radius: 30, x: 0, y: 30)
            }
            .contentShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .medium), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// An accent stroke on a light track with round caps. `progress` is the filled fraction.
public struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let track: Color
    let tint: Color

    public init(progress: Double, lineWidth: CGFloat = 5, track: Color = StillColor.divider, tint: Color = StillColor.accent) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.track = track
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}
#endif
