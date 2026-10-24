import Foundation
import UserNotifications

@MainActor public protocol NotificationCenterProtocol {
    func removeAllPending()
    func add(_ notification: PlannedNotification, calendar: Calendar) async
}

@MainActor public struct SystemNotificationCenter: NotificationCenterProtocol {
    public init() {}

    public func removeAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    public func add(_ n: PlannedNotification, calendar: Calendar) async {
        let content = UNMutableNotificationContent()
        content.title = n.title
        content.body = n.body
        content.sound = .default
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: n.fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: n.id, content: content, trigger: trigger))
    }

    public static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}

@MainActor
public final class NotificationScheduler {
    private let center: NotificationCenterProtocol

    public init(center: NotificationCenterProtocol = SystemNotificationCenter()) {
        self.center = center
    }

    public func reschedule(items: [TodoItem], settings: NotificationSettings, now: Date, calendar: Calendar, reminderCategories: Set<UUID>, lastActivity: Date) async {
        center.removeAllPending()
        for n in planNotifications(items: items, settings: settings, now: now, calendar: calendar, reminderCategories: reminderCategories, lastActivity: lastActivity) {
            await center.add(n, calendar: calendar)
        }
    }
}
