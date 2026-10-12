import DesignSystem
import FamilyControls
import ManagedSettings
import StillKit
import SwiftUI

/// The selected apps, categories and websites as a row of icons, e.g. under
/// "Blocking 2 apps and 3 categories". iOS only exposes them through `Label(token)`,
/// which renders the real app icon or category symbol.
struct SelectionIcons: View {
    /// How many tiles fit; the last one becomes "+N" when there are more.
    let limit: Int
    var tileSize: CGFloat = 34

    @Environment(AppModel.self) private var model

    var body: some View {
        let items = self.items
        let overflow = max(0, items.count - limit)
        let shown = overflow > 0 ? Array(items.prefix(limit - 1)) : items

        HStack(spacing: 6) {
            ForEach(shown) { item in
                tile { item.icon }
            }
            if overflow > 0 {
                tile(filled: true) {
                    Text(verbatim: "+\(overflow + 1)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(StillColor.inkSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Formatters.blockingTitle(model.selectionSummary)))
    }

    private func tile<Content: View>(filled: Bool = false, @ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(width: tileSize, height: tileSize)
            .background {
                RoundedRectangle(cornerRadius: tileSize * 0.26, style: .continuous)
                    .fill(filled ? StillColor.fill : StillColor.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: tileSize * 0.26, style: .continuous)
                    .strokeBorder(StillColor.border, lineWidth: 1)
            }
    }

    // MARK: Items

    private struct Item: Identifiable {
        let id: String
        let icon: AnyView
    }

    private var items: [Item] {
        #if DEBUG
        if model.config.isDemo {
            return Self.demoItems(count: model.selectionSummary.total)
        }
        #endif
        let selection = model.selection
        let iconSize = tileSize * 0.74
        var result: [Item] = []
        // Apps first (their icons are the most recognisable), then categories, then websites.
        for token in selection.applicationTokens {
            result.append(Item(id: "a\(token.hashValue)", icon: AnyView(
                Label(token).labelStyle(.iconOnly).font(.system(size: iconSize))
            )))
        }
        for token in selection.categoryTokens {
            result.append(Item(id: "c\(token.hashValue)", icon: AnyView(
                Label(token).labelStyle(.iconOnly).font(.system(size: iconSize * 0.7))
            )))
        }
        for token in selection.webDomainTokens {
            result.append(Item(id: "w\(token.hashValue)", icon: AnyView(
                Label(token).labelStyle(.iconOnly).font(.system(size: iconSize * 0.7))
            )))
        }
        return result
    }

    #if DEBUG
    /// Demo mode has no real tokens; show category-like symbols instead.
    private static func demoItems(count: Int) -> [Item] {
        let symbols = ["bubble.left.and.bubble.right.fill", "play.rectangle.fill", "newspaper.fill",
                       "gamecontroller.fill", "bag.fill", "globe"]
        return (0..<min(count, symbols.count)).map { index in
            Item(id: symbols[index], icon: AnyView(
                Image(systemName: symbols[index])
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(StillColor.ink)
            ))
        }
    }
    #endif
}
