import SwiftUI
import TodoCore

struct TodoRow: View {
    let item: TodoItem
    let now: Date
    let calendar: Calendar
    let onDone: () -> Void

    var body: some View {
        let due = DueLabel(item: item, now: now, calendar: calendar)
        HStack(spacing: 11) {
            Button(action: onDone) {
                Circle().strokeBorder(.secondary.opacity(0.6), lineWidth: 1.5).frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Yapıldı")
            (Text(item.person.map { "\($0)" } ?? "").fontWeight(.semibold)
                + Text(item.person == nil ? "" : " · ")
                + Text(item.action))
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(due.text)
                .font(.system(size: 12))
                .foregroundStyle(due.isOverdue ? Color.red : Color.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
    }
}
