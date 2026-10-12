#if os(iOS)
import SwiftUI

/// Type styles from the design. SF Pro (the system font) throughout; sizes of
/// 20 pt and up automatically use SF Pro Display.
///
/// Every style scales with Dynamic Type relative to a matching text style. The
/// very large display styles are capped so they never clip.
public enum StillFont: Sendable {
    /// 44 pt bold, onboarding headline.
    case hero
    /// 40 pt bold, Home "This week" stat and the shield title.
    case stat
    /// 34 pt bold, screen titles.
    case title
    /// 32 pt bold, paywall title.
    case paywallTitle
    /// 30 pt semibold, "Be still" in the big circle.
    case circleTitle
    /// 28 pt bold, "Still needs Screen Time access".
    case title2
    /// 62 pt light, monospaced digits, session countdown.
    case timer
    /// 22 pt semibold, numbers in stat cards.
    case statValue
    /// 20 pt bold, dialog and sheet titles.
    case dialogTitle
    /// 17 pt semibold, button labels and the logo wordmark.
    case button
    /// 17 pt regular.
    case body
    /// 16 pt regular, list rows.
    case callout
    /// 16 pt medium, list row titles.
    case calloutMedium
    /// 15 pt regular, secondary lines.
    case subheadline
    /// 14 pt medium, segmented control.
    case segment
    /// 14 pt semibold, selected segment.
    case segmentSelected
    /// 13 pt regular, footnotes and helper text.
    case footnote
    /// 13 pt semibold, pills and section headers.
    case footnoteEmphasized
    /// 12 pt regular.
    case caption
    /// 12 pt semibold, badges.
    case captionEmphasized

    struct Spec {
        var size: CGFloat
        var weight: Font.Weight
        var relativeTo: Font.TextStyle
        /// Letter spacing in em (multiplied by the point size).
        var trackingEm: CGFloat = 0
        var monospacedDigits = false
        /// The largest size Dynamic Type may scale this style to.
        var maxSize: CGFloat = .infinity
    }

    var spec: Spec {
        switch self {
        case .hero: Spec(size: 44, weight: .bold, relativeTo: .largeTitle, trackingEm: -0.04, maxSize: 56)
        case .stat: Spec(size: 40, weight: .bold, relativeTo: .largeTitle, trackingEm: -0.035, maxSize: 52)
        case .title: Spec(size: 34, weight: .bold, relativeTo: .largeTitle, trackingEm: -0.035, maxSize: 48)
        case .paywallTitle: Spec(size: 32, weight: .bold, relativeTo: .largeTitle, trackingEm: -0.035, maxSize: 44)
        case .circleTitle: Spec(size: 30, weight: .semibold, relativeTo: .title, trackingEm: -0.03, maxSize: 36)
        case .title2: Spec(size: 28, weight: .bold, relativeTo: .title, trackingEm: -0.03, maxSize: 40)
        case .timer: Spec(size: 62, weight: .light, relativeTo: .largeTitle, trackingEm: -0.04, monospacedDigits: true, maxSize: 62)
        case .statValue: Spec(size: 22, weight: .semibold, relativeTo: .title2, trackingEm: -0.02, maxSize: 34)
        case .dialogTitle: Spec(size: 20, weight: .bold, relativeTo: .title3, trackingEm: -0.02)
        case .button: Spec(size: 17, weight: .semibold, relativeTo: .headline, maxSize: 28)
        case .body: Spec(size: 17, weight: .regular, relativeTo: .body)
        case .callout: Spec(size: 16, weight: .regular, relativeTo: .callout)
        case .calloutMedium: Spec(size: 16, weight: .medium, relativeTo: .callout)
        case .subheadline: Spec(size: 15, weight: .regular, relativeTo: .subheadline)
        case .segment: Spec(size: 14, weight: .medium, relativeTo: .subheadline, maxSize: 20)
        case .segmentSelected: Spec(size: 14, weight: .semibold, relativeTo: .subheadline, maxSize: 20)
        case .footnote: Spec(size: 13, weight: .regular, relativeTo: .footnote)
        case .footnoteEmphasized: Spec(size: 13, weight: .semibold, relativeTo: .footnote)
        case .caption: Spec(size: 12, weight: .regular, relativeTo: .caption)
        case .captionEmphasized: Spec(size: 12, weight: .semibold, relativeTo: .caption)
        }
    }

    /// The font at its unscaled design size (used where Dynamic Type doesn't apply, e.g. widgets).
    public var fixedFont: Font {
        let spec = spec
        let font = Font.system(size: spec.size, weight: spec.weight)
        return spec.monospacedDigits ? font.monospacedDigit() : font
    }
}

private struct StillFontModifier: ViewModifier {
    let style: StillFont
    @ScaledMetric private var scaledSize: CGFloat

    init(style: StillFont) {
        self.style = style
        _scaledSize = ScaledMetric(wrappedValue: style.spec.size, relativeTo: style.spec.relativeTo)
    }

    func body(content: Content) -> some View {
        let spec = style.spec
        let size = min(scaledSize, spec.maxSize)
        let font = Font.system(size: size, weight: spec.weight)
        return content
            .font(spec.monospacedDigits ? font.monospacedDigit() : font)
            .tracking(spec.trackingEm * size)
    }
}

extension View {
    /// Applies a Still type style (font, tracking and Dynamic Type scaling).
    public func stillFont(_ style: StillFont) -> some View {
        modifier(StillFontModifier(style: style))
    }
}
#endif
