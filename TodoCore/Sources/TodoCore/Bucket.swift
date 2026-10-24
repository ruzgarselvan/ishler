import Foundation

public enum Bucket: Int, Comparable, Sendable {
    case overdue, today, thisWeek, later

    public static func < (a: Bucket, b: Bucket) -> Bool { a.rawValue < b.rawValue }
}

public func bucket(for item: TodoItem, now: Date, calendar: Calendar) -> Bucket {
    guard let due = item.dueDate else { return .today }
    let days = calendar.dateComponents(
        [.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)
    ).day ?? 0
    switch days {
    case ..<0: return .overdue
    case 0: return .today
    case 1...7: return .thisWeek
    default: return .later
    }
}

public func sortedOpenItems(_ items: [TodoItem], now: Date, calendar: Calendar) -> [(Bucket, [TodoItem])] {
    let open = items.filter { !$0.isDone }
    let grouped = Dictionary(grouping: open) { bucket(for: $0, now: now, calendar: calendar) }
    return grouped.keys.sorted().map { key in
        let sorted = grouped[key]!.sorted { a, b in
            switch (a.dueDate, b.dueDate) {
            case let (x?, y?): return x < y
            case (_?, nil): return true
            default: return false
            }
        }
        return (key, sorted)
    }
}
