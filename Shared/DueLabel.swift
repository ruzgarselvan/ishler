import Foundation
import SwiftUI
import TodoCore

struct DueLabel {
    let text: String
    let isOverdue: Bool

    init(item: TodoItem, now: Date, calendar: Calendar) {
        guard let due = item.dueDate else { text = "Bekliyor"; isOverdue = false; return }
        (text, isOverdue) = dueLabelText(due: due, now: now, calendar: calendar)
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
