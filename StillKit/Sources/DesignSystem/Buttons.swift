#if os(iOS)
import SwiftUI

/// The dark "shadcn-style" primary button: vertical gradient, inner top highlight,
/// inner bottom shade, 1 px outer ring and a soft drop shadow.
public struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat
    var radius: CGFloat
    var font: StillFont

    public init(height: CGFloat = StillSize.button, radius: CGFloat = StillRadius.card, font: StillFont = .button) {
        self.height = height
        self.radius = radius
        self.font = font
    }

    public func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration, height: height, radius: radius, font: font)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let height: CGFloat
    let radius: CGFloat
    let font: StillFont
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        configuration.label
            .stillFont(font)
            .foregroundStyle(StillColor.onPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: height)
            .background {
                shape.fill(
                    LinearGradient(
                        colors: [StillColor.primaryTop, StillColor.primaryBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .shadow(.inner(color: .white.opacity(0.18), radius: 0, x: 0, y: 1))
                    .shadow(.inner(color: .black.opacity(0.3), radius: 0, x: 0, y: -1))
                )
            }
            .overlay {
                // Pressed state: a touch darker.
                shape.fill(Color.black.opacity(configuration.isPressed ? 0.14 : 0))
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius + 1, style: .continuous)
                    .strokeBorder(StillColor.primaryRing, lineWidth: 1)
                    .padding(-1)
            }
            .shadow(color: StillColor.shadow.opacity(0.16), radius: 2, x: 0, y: 2)
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// The light secondary button: surface fill, ink label, 1 px border ring,
/// inner bottom shade and a faint shadow.
public struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat
    var radius: CGFloat
    var font: StillFont

    public init(height: CGFloat = StillSize.button, radius: CGFloat = StillRadius.card, font: StillFont = .button) {
        self.height = height
        self.radius = radius
        self.font = font
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .stillFont(font)
            .foregroundStyle(StillColor.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: height)
            .background { SecondarySurface(radius: radius, isPressed: configuration.isPressed) }
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

/// The surface behind secondary buttons, round icon buttons and the hold button.
public struct SecondarySurface: View {
    var radius: CGFloat
    var isPressed: Bool

    public init(radius: CGFloat = StillRadius.card, isPressed: Bool = false) {
        self.radius = radius
        self.isPressed = isPressed
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(StillColor.surface.shadow(.inner(color: .black.opacity(0.06), radius: 0, x: 0, y: -1)))
            .overlay { shape.fill(StillColor.ink.opacity(isPressed ? 0.05 : 0)) }
            .overlay {
                RoundedRectangle(cornerRadius: radius + 1, style: .continuous)
                    .strokeBorder(StillColor.border, lineWidth: 1)
                    .padding(-1)
            }
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

/// A round 40 pt button with a secondary surface (settings, back).
public struct CircleIconButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    public init(systemImage: String, accessibilityLabel: LocalizedStringKey, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(StillColor.ink)
                .frame(width: StillSize.iconButton, height: StillSize.iconButton)
                .background { SecondarySurface(radius: StillSize.iconButton / 2) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

/// The 32 pt close button on sheets and the paywall.
public struct CloseButton: View {
    let action: () -> Void

    public init(action: @escaping () -> Void) {
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(StillColor.inkSecondary)
                .frame(width: StillSize.closeButton, height: StillSize.closeButton)
                .background(Circle().fill(StillColor.fill))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Close"))
        .accessibilityIdentifier("close")
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var stillPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    public static var stillSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
#endif
