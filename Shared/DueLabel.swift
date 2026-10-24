import Foundation
import SwiftUI
import TodoCore

struct DueLabel {
    let text: String
    let isOverdue: Bool

    init(item: TodoItem, now: Date, calendar: Calendar) {
        guard let due = item.dueDate else { text = "Bekliyor"; isOverdue = false; return }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
        isOverdue = days < 0
        switch days {
        case ..<(-1): text = "\(-days) gün önce"
        case -1: text = "Dün"
        case 0: text = "Bugün"
        case 1: text = "Yarın"
        default: text = due.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR")))
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

func itemLabel(_ item: TodoItem) -> Text {
    guard let person = item.person else { return Text(item.action) }
    return Text("\(Text(person).fontWeight(.semibold)) · \(item.action)")
}
