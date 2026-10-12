import Foundation
import ManagedSettings
import StillKit

/// Handles the shield's buttons. "Close" counts one resisted urge in the App Group
/// and closes the blocked app.
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(respond(to: action))
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(respond(to: action))
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(respond(to: action))
    }

    private func respond(to action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            SharedStore.shared.recordUrge(at: Date())
            return .close
        case .secondaryButtonPressed:
            // The secondary line ("You chose this at 21:45.") is informational.
            return .none
        @unknown default:
            return .close
        }
    }
}
