import Foundation

public struct NotificationSettings: Codable, Equatable, Sendable {
    public var eveningTime: DateComponents
    public var morningTime: DateComponents
    public var digestTime: DateComponents
    public var eveningDaysBefore: Int

    public init(eveningTime: DateComponents, morningTime: DateComponents, digestTime: DateComponents, eveningDaysBefore: Int) {
        self.eveningTime = eveningTime
        self.morningTime = morningTime
        self.digestTime = digestTime
        self.eveningDaysBefore = eveningDaysBefore
    }

    public static let `default` = NotificationSettings(
        eveningTime: DateComponents(hour: 20, minute: 0),
        morningTime: DateComponents(hour: 10, minute: 30),
        digestTime: DateComponents(hour: 12, minute: 0),
        eveningDaysBefore: 3
    )
}

public struct PlannedNotification: Equatable, Sendable {
    public let id: String
    public let fireDate: Date
    public let title: String
    public let body: String
    /// Set for notifications about one item, so actions ("Yapıldı", "Ertele") know which one.
    public let itemID: UUID?

    public init(id: String, fireDate: Date, title: String, body: String, itemID: UUID? = nil) {
        self.id = id
        self.fireDate = fireDate
        self.title = title
        self.body = body
        self.itemID = itemID
    }
}

private let maxPending = 60
private let digestDays = 14
/// The "Seni bekleyen işler var!" nudge only starts after this many days without opening or changing anything.
private let digestAfterInactiveDays = 2

public func planNotifications(
    items: [TodoItem], settings: NotificationSettings, now: Date, calendar: Calendar,
    reminderCategories: Set<UUID>, lastActivity: Date
) -> [PlannedNotification] {
    let today = calendar.startOfDay(for: now)
    func at(_ day: Date, _ time: DateComponents) -> Date {
        calendar.date(bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0, of: day)!
    }
    func line(_ item: TodoItem) -> String {
        item.person.map { "\($0) · \(item.action)" } ?? item.action
    }

    var out: [PlannedNotification] = []
    var digestItems: [TodoItem] = []

    for item in items where !item.isDone {
        guard let category = item.categoryID, reminderCategories.contains(category) else { continue }
        guard let due = item.dueDate else { digestItems.append(item); continue }
        let dueDay = calendar.startOfDay(for: due)
        if dueDay < today { digestItems.append(item); continue }
        if settings.eveningDaysBefore >= 1 {
            for k in 1...settings.eveningDaysBefore {
                let day = calendar.date(byAdding: .day, value: -k, to: dueDay)!
                let clock = item.dueMinutes.map { " " + timeString($0) } ?? ""
                let when = k == 1 ? "Yarın\(clock)" : "\(longDate(dueDay, calendar: calendar))\(clock) · \(k) gün kaldı"
                out.append(PlannedNotification(
                    id: "item-\(item.id.uuidString)-evening-\(k)",
                    fireDate: at(day, settings.eveningTime),
                    title: line(item), body: when, itemID: item.id))
            }
        }
        if let minutes = item.dueMinutes {
            out.append(PlannedNotification(
                id: "item-\(item.id.uuidString)-time",
                fireDate: at(dueDay, DateComponents(hour: minutes / 60, minute: minutes % 60)),
                title: line(item), body: "Şimdi · \(timeString(minutes))", itemID: item.id))
        } else {
            out.append(PlannedNotification(
                id: "item-\(item.id.uuidString)-morning",
                fireDate: at(dueDay, settings.morningTime),
                title: line(item), body: "Bugün", itemID: item.id))
        }
    }

    if !digestItems.isEmpty {
        let first = calendar.date(byAdding: .day, value: digestAfterInactiveDays, to: calendar.startOfDay(for: lastActivity))!
        for offset in 0..<digestDays {
            let day = calendar.date(byAdding: .day, value: offset, to: first)!
            let body = digestItems.map { item in
                guard let due = item.dueDate else { return line(item) }
                return "\(line(item)) · \(dueLabelText(due: due, now: day, calendar: calendar).text)"
            }.joined(separator: "\n")
            let c = calendar.dateComponents([.year, .month, .day], from: day)
            out.append(PlannedNotification(
                id: String(format: "digest-%04d-%02d-%02d", c.year!, c.month!, c.day!),
                fireDate: at(day, settings.digestTime),
                title: "Seni bekleyen işler var!", body: body))
        }
    }

    return Array(out.filter { $0.fireDate > now }.sorted { $0.fireDate < $1.fireDate }.prefix(maxPending))
}

func timeString(_ minutes: Int) -> String { String(format: "%02d:%02d", minutes / 60, minutes % 60) }
