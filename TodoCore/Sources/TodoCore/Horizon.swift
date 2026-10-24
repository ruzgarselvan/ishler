import Foundation

public enum Horizon: String, Codable, CaseIterable, Sendable {
    case week, month, all

    var maxDays: Int? {
        switch self {
        case .week: 7
        case .month: 31
        case .all: nil
        }
    }
}

/// Undated and overdue items are always visible; dated ones only within the horizon.
public func isVisible(_ item: TodoItem, horizon: Horizon, now: Date, calendar: Calendar) -> Bool {
    guard let due = item.dueDate, let limit = horizon.maxDays else { return true }
    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
    return days <= limit
}
