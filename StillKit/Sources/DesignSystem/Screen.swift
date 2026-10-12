#if os(iOS)
import SwiftUI

/// The standard screen container: paper background, 20 pt margins, and content
/// that fills the screen (so spacers work) but scrolls when Dynamic Type makes it taller.
public struct StillScreen<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    public init(spacing: CGFloat = StillSpacing.section, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: spacing) {
                    content
                }
                .padding(.horizontal, StillSpacing.screen)
                .padding(.top, StillSpacing.top)
                .padding(.bottom, StillSpacing.bottom)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .background(StillColor.background.ignoresSafeArea())
    }
}

/// The 44 pt top bar row.
public struct StillTopBar<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing

    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack {
            leading
            Spacer(minLength: 8)
            trailing
        }
        .frame(minHeight: StillSpacing.topBar)
    }
}

extension StillTopBar where Trailing == EmptyView {
    public init(@ViewBuilder leading: () -> Leading) {
        self.init(leading: leading, trailing: { EmptyView() })
    }
}
#endif
