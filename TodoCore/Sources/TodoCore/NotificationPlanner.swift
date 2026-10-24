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
}

private let maxPending = 60
private let digestDays = 14

public func planNotifications(
    items: [TodoItem], settings: NotificationSettings, now: Date, calendar: Calendar
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
        guard let due = item.dueDate else { digestItems.append(item); continue }
        let dueDay = calendar.startOfDay(for: due)
        if dueDay < today { digestItems.append(item); continue }
        if settings.eveningDaysBefore >= 1 {
            for k in 1...settings.eveningDaysBefore {
                let day = calendar.date(byAdding: .day, value: -k, to: dueDay)!
                out.append(PlannedNotification(
                    id: "item-\(item.id.uuidString)-evening-\(k)",
                    fireDate: at(day, settings.eveningTime),
                    title: "\(k) gün kaldı", body: line(item)))
            }
        }
        out.append(PlannedNotification(
            id: "item-\(item.id.uuidString)-morning",
            fireDate: at(dueDay, settings.morningTime),
            title: "Bugün teslim", body: line(item)))
    }

    if !digestItems.isEmpty {
        let body = digestItems.map(line).joined(separator: "\n")
        for offset in 0..<digestDays {
            let day = calendar.date(byAdding: .day, value: offset, to: today)!
            let c = calendar.dateComponents([.year, .month, .day], from: day)
            out.append(PlannedNotification(
                id: String(format: "digest-%04d-%02d-%02d", c.year!, c.month!, c.day!),
                fireDate: at(day, settings.digestTime),
                title: "Bekleyen işler", body: body))
        }
    }

    return Array(out.filter { $0.fireDate > now }.sorted { $0.fireDate < $1.fireDate }.prefix(maxPending))
}
