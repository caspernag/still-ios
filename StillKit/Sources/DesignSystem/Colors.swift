#if os(iOS)
import SwiftUI
import UIKit

extension UIColor {
    /// A color from a 0xRRGGBB value.
    public convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    /// A color that switches between a light and a dark value.
    public static func still(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

/// Color tokens as UIColor (used by the shield extension and wherever UIKit needs them).
///
/// Light values come straight from the design. Dark values keep the same calm,
/// warm feel: a deep ink paper, soft surfaces and the same apricot accent.
public enum StillPalette {
    /// Screen background (warm paper).
    public static var background: UIColor { .still(light: 0xF7F6F3, dark: 0x121417) }
    /// Cards, grouped lists, secondary buttons.
    public static var surface: UIColor { .still(light: 0xFFFFFF, dark: 0x1C1F24) }
    /// Primary text and icons.
    public static var ink: UIColor { .still(light: 0x1B1F24, dark: 0xECEDEF) }
    /// Secondary text.
    public static var inkSecondary: UIColor { .still(light: 0x5F6670, dark: 0x9A9DA3) }
    /// Chevrons, dimmed picker values.
    public static var inkMuted: UIColor { .still(light: 0xA7A9AE, dark: 0x6B7078) }
    /// 1 px ring around cards and secondary buttons.
    public static var border: UIColor { .still(light: 0xE7E5DF, dark: 0x2C3037) }
    /// Inset list dividers and halo rings.
    public static var divider: UIColor { .still(light: 0xEFEDE8, dark: 0x252930) }
    /// Segmented-control track, toggle-off track, close-button circle.
    public static var fill: UIColor { .still(light: 0xECEAE4, dark: 0x2A2D33) }
    /// Apricot: logo dot, progress ring, toggles, live dot.
    public static var accent: UIColor { .still(light: 0xFF9F7A, dark: 0xFF9F7A) }
    /// Apricot as text (contrast-safe on paper and on ink).
    public static var accentText: UIColor { .still(light: 0xD9663F, dark: 0xFFA884) }
    /// Peach: "Be still" circle, icon and number tiles, badges.
    public static var accentSoft: UIColor { .still(light: 0xFFE9DF, dark: 0x3A2921) }
    /// Session-complete circle.
    public static var successSoft: UIColor { .still(light: 0xCDEFDB, dark: 0x1D3527) }
    /// Session-complete ring and check.
    public static var success: UIColor { .still(light: 0x49DE24, dark: 0x5FE33E) }
    /// Inactive step dots, grabbers.
    public static var neutral: UIColor { .still(light: 0xD5D3CD, dark: 0x3A3E45) }
    /// Primary button gradient (top).
    public static var primaryTop: UIColor { .still(light: 0x2E3540, dark: 0xF4F3EF) }
    /// Primary button gradient (bottom).
    public static var primaryBottom: UIColor { .still(light: 0x1B1F24, dark: 0xDCDAD3) }
    /// Primary button 1 px outer ring.
    public static var primaryRing: UIColor { .still(light: 0x12151A, dark: 0xBDBAB2) }
    /// Label on the primary button.
    public static var onPrimary: UIColor { .still(light: 0xFFFFFF, dark: 0x1B1F24) }
    /// Logo circle (always ink, so the mark reads the same on every background).
    public static var logo: UIColor { .still(light: 0x1B1F24, dark: 0x2E3540) }
    /// Dimmed backdrop behind dialogs and sheets.
    public static var scrim: UIColor { UIColor(hex: 0x1B1F24, alpha: 0.32) }
    /// Soft shadow tint.
    public static var shadow: UIColor { .still(light: 0x1B1F24, dark: 0x000000) }
}

/// Color tokens for SwiftUI. Screens use only these.
public enum StillColor {
    public static var background: Color { Color(uiColor: StillPalette.background) }
    public static var surface: Color { Color(uiColor: StillPalette.surface) }
    public static var ink: Color { Color(uiColor: StillPalette.ink) }
    public static var inkSecondary: Color { Color(uiColor: StillPalette.inkSecondary) }
    public static var inkMuted: Color { Color(uiColor: StillPalette.inkMuted) }
    public static var border: Color { Color(uiColor: StillPalette.border) }
    public static var divider: Color { Color(uiColor: StillPalette.divider) }
    public static var fill: Color { Color(uiColor: StillPalette.fill) }
    public static var accent: Color { Color(uiColor: StillPalette.accent) }
    public static var accentText: Color { Color(uiColor: StillPalette.accentText) }
    public static var accentSoft: Color { Color(uiColor: StillPalette.accentSoft) }
    public static var successSoft: Color { Color(uiColor: StillPalette.successSoft) }
    public static var success: Color { Color(uiColor: StillPalette.success) }
    public static var neutral: Color { Color(uiColor: StillPalette.neutral) }
    public static var primaryTop: Color { Color(uiColor: StillPalette.primaryTop) }
    public static var primaryBottom: Color { Color(uiColor: StillPalette.primaryBottom) }
    public static var primaryRing: Color { Color(uiColor: StillPalette.primaryRing) }
    public static var onPrimary: Color { Color(uiColor: StillPalette.onPrimary) }
    public static var logo: Color { Color(uiColor: StillPalette.logo) }
    public static var scrim: Color { Color(uiColor: StillPalette.scrim) }
    public static var shadow: Color { Color(uiColor: StillPalette.shadow) }

    /// Fixed colors used on the always-dark Dynamic Island.
    public enum Island {
        public static var text: Color { Color(uiColor: UIColor(hex: 0xECEDEF)) }
        public static var secondary: Color { Color(uiColor: UIColor(hex: 0x9A9DA3)) }
        public static var track: Color { Color(uiColor: UIColor(hex: 0x2A2C30)) }
    }
}
#endif
