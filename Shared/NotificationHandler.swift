import Foundation
import UserNotifications
import TodoCore

/// Handles the "Yapıldı" / "1 saat sonra" / "Yarın" buttons on item notifications.
final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    @MainActor weak var model: AppModel?

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let content = response.notification.request.content
        guard let raw = content.userInfo[NotificationActions.itemKey] as? String, let id = UUID(uuidString: raw) else { return }
        let action = response.actionIdentifier
        let title = content.title
        let body = content.body
        await MainActor.run { model?.handle(action: action, itemID: id, title: title, body: body) }
    }
}
