import Foundation
import StillKit
import UserNotifications

/// Local "session done" notifications.
@MainActor
final class NotificationService {
    private var center: UNUserNotificationCenter { .current() }

    private func identifier(_ sessionID: UUID) -> String {
        "still.session.\(sessionID.uuidString)"
    }

    /// Asks for permission. Returns whether notifications are allowed.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    func scheduleSessionDone(_ session: Session, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .active

        let interval = max(1, session.end.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(session.id), content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    func cancel(_ sessionID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier(sessionID)])
    }
}
