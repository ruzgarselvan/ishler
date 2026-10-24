import Foundation

/// How a due date reads next to an item: "Bugün", "Yarın", "23 Kasım", "Dün", "3 gün önce".
public func dueLabelText(due: Date, now: Date, calendar: Calendar) -> (text: String, isOverdue: Bool) {
    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
    switch days {
    case ..<(-1): return ("\(-days) gün önce", true)
    case -1: return ("Dün", true)
    case 0: return ("Bugün", false)
    case 1: return ("Yarın", false)
    default: return (longDate(due, calendar: calendar), false)
    }
}

func longDate(_ date: Date, calendar: Calendar) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "tr_TR")
    f.calendar = calendar
    f.timeZone = calendar.timeZone
    f.dateFormat = "d MMMM"
    return f.string(from: date)
}
