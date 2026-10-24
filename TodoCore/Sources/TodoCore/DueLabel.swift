import Foundation

/// How a due date reads next to an item: "Bugün", "Yarın", "23 Kasım", "Dün", "3 gün önce".
public func dueLabelText(due: Date, now: Date, calendar: Calendar) -> (text: String, isOverdue: Bool) {
    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
    switch days {
    case ..<(-1): return (String(localized: "\(-days) gün önce"), true)
    case -1: return (String(localized: "Dün"), true)
    case 0: return (String(localized: "Bugün"), false)
    case 1: return (String(localized: "Yarın"), false)
    default: return (longDate(due, calendar: calendar), false)
    }
}

func longDate(_ date: Date, calendar: Calendar) -> String {
    let f = DateFormatter()
    f.calendar = calendar
    f.timeZone = calendar.timeZone
    f.locale = calendar.locale ?? .current
    f.setLocalizedDateFormatFromTemplate("dMMMM")
    return f.string(from: date)
}
