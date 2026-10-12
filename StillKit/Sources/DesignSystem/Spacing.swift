#if os(iOS)
import CoreGraphics

/// Spacing, sizes and radii from the design.
public enum StillSpacing {
    /// Horizontal screen margin.
    public static let screen: CGFloat = 20
    /// Default vertical gap between sections on a screen.
    public static let section: CGFloat = 22
    /// Top padding below the safe area (the design's 60 px include the status bar).
    public static let top: CGFloat = 0
    /// Bottom padding above the safe area.
    public static let bottom: CGFloat = 8
    /// Height of the top bar row (logo, settings button).
    public static let topBar: CGFloat = 44
    /// Horizontal padding inside list rows and cards.
    public static let rowHorizontal: CGFloat = 16
    /// Vertical padding inside list rows.
    public static let rowVertical: CGFloat = 14
    /// Gap between stacked buttons.
    public static let buttonGap: CGFloat = 12
}

public enum StillRadius {
    /// Cards, grouped lists and buttons.
    public static let card: CGFloat = 14
    /// Segmented control track.
    public static let control: CGFloat = 10
    /// Selected segment pill.
    public static let segment: CGFloat = 8
    /// Icon and number tiles.
    public static let tile: CGFloat = 8
    /// Dialog card.
    public static let dialog: CGFloat = 22
    /// Bottom sheet top corners.
    public static let sheet: CGFloat = 28
}

public enum StillSize {
    /// Primary and secondary button height.
    public static let button: CGFloat = 52
    /// Dialog button height.
    public static let dialogButton: CGFloat = 48
    /// "Be still" circle diameter.
    public static let bigCircle: CGFloat = 240
    /// Halo ring around the big circle.
    public static let halo: CGFloat = 10
    /// Session progress ring diameter.
    public static let ring: CGFloat = 280
    /// Session-complete circle diameter.
    public static let completeCircle: CGFloat = 200
    /// Round icon buttons (settings, back).
    public static let iconButton: CGFloat = 40
    /// Close button circle.
    public static let closeButton: CGFloat = 32
}
#endif
