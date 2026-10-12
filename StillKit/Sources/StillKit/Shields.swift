#if os(iOS)
import FamilyControls
import Foundation
import ManagedSettings

extension ManagedSettingsStore.Name {
    /// The store used by manual sessions.
    public static let stillSession = Self(ActivityNaming.sessionStoreName)

    /// The store used by one schedule.
    public static func stillSchedule(_ scheduleID: UUID) -> Self {
        Self(ActivityNaming.scheduleStoreName(scheduleID))
    }
}

/// Applies and clears shields in a named ManagedSettingsStore.
public enum Shields {
    /// Shields everything in `selection`: single apps, whole categories (apps and
    /// websites in them) and single websites.
    public static func apply(_ selection: FamilyActivitySelection, to name: ManagedSettingsStore.Name) {
        let store = ManagedSettingsStore(named: name)
        let apps = selection.applicationTokens
        let categories = selection.categoryTokens
        let domains = selection.webDomainTokens
        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
        store.shield.webDomains = domains.isEmpty ? nil : domains
        store.shield.webDomainCategories = categories.isEmpty ? nil : .specific(categories)
    }

    /// Removes every shield and setting from the store.
    public static func clear(_ name: ManagedSettingsStore.Name) {
        ManagedSettingsStore(named: name).clearAllSettings()
    }
}
#endif
