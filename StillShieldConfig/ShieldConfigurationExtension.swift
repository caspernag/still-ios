import DesignSystem
import Foundation
import ManagedSettings
import ManagedSettingsUI
import StillKit
import UIKit

/// The screen iOS shows when a blocked app or website is opened (screen 5),
/// matched to the design as far as ShieldConfiguration allows: background,
/// logo icon, title, subtitle, a dark "Close" button and a quiet secondary line.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let store = SharedStore.shared
        let now = Date()
        var subtitle = String(localized: "This app can wait.")

        if let session = store.activeSession, !SessionMath.isExpired(session, now: now) {
            let end = Self.time(session.end)
            let start = Self.time(session.start)
            let chose = String(localized: "You chose this at \(start).")
            subtitle = String(localized: "This app can wait. Your session ends at \(end).") + "\n\n" + chose
        } else if let active = ScheduleMapping.activeSchedule(in: store.schedules, at: now, calendar: .current) {
            let end = Self.time(active.end)
            let name = active.schedule.name
            subtitle = String(localized: "This app can wait. \(name) ends at \(end).")
        }

        return ShieldConfiguration(
            backgroundBlurStyle: nil,
            backgroundColor: StillPalette.background,
            icon: Self.logoImage(),
            title: ShieldConfiguration.Label(text: String(localized: "Be still."), color: StillPalette.ink),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: StillPalette.inkSecondary),
            primaryButtonLabel: ShieldConfiguration.Label(text: String(localized: "Close"), color: StillPalette.onPrimary),
            primaryButtonBackgroundColor: StillPalette.primaryBottom,
            secondaryButtonLabel: nil
        )
    }

    private static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    /// The logo mark with its halo (light and dark variants live in the asset catalog).
    private static func logoImage() -> UIImage? {
        UIImage(named: "ShieldIcon")
    }
}
