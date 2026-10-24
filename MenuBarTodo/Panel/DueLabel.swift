import Foundation
import TodoCore

struct DueLabel {
    let text: String
    let isOverdue: Bool

    init(item: TodoItem, now: Date, calendar: Calendar) {
        guard let due = item.dueDate else { text = "Bekliyor"; isOverdue = false; return }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
        isOverdue = days < 0
        switch days {
        case ..<0: text = "\(-days) gün"
        case 0: text = "Bugün"
        case 1...7: text = due.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "tr_TR")))
        default: text = due.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "tr_TR")))
        }
    }
}

func bucketTitle(_ b: Bucket) -> String {
    switch b {
    case .overdue: "Gecikmiş"
    case .today: "Bugün"
    case .thisWeek: "Bu hafta"
    case .later: "Daha sonra"
    }
}
