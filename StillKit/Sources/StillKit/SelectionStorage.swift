#if os(iOS)
import FamilyControls
import Foundation

/// Persists the user's FamilyActivitySelection (which is Codable) in the App Group,
/// together with a small summary the widget and extensions can read cheaply.
public enum SelectionStorage {
    public static func load(from store: SharedStore = .shared) -> FamilyActivitySelection {
        guard let data = store.selectionData,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection(includeEntireCategory: true) }
        return selection
    }

    public static func save(_ selection: FamilyActivitySelection, to store: SharedStore = .shared) {
        store.selectionData = try? JSONEncoder().encode(selection)
        store.selectionSummary = summary(of: selection)
    }

    public static func summary(of selection: FamilyActivitySelection) -> SelectionSummary {
        SelectionSummary(
            applications: selection.applicationTokens.count,
            categories: selection.categoryTokens.count,
            webDomains: selection.webDomainTokens.count
        )
    }
}
#endif
