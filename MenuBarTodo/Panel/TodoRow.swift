import SwiftUI
import TodoCore

struct TodoRow: View {
    let item: TodoItem
    let now: Date
    let calendar: Calendar
    let onDone: () -> Void

    var body: some View {
        let due = DueLabel(item: item, now: now, calendar: calendar)
        HStack(spacing: 9) {
            Button(action: onDone) {
                Circle().strokeBorder(.secondary.opacity(0.6), lineWidth: 1.3).frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .help("Yapıldı")
            label
                .font(.system(size: 13))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(due.text)
                .font(.system(size: 11))
                .foregroundStyle(due.isOverdue ? Color.red : Color.secondary)
        }
        .padding(.vertical, 4)
    }

    private var label: Text {
        guard let person = item.person else { return Text(item.action) }
        return Text("\(Text(person).fontWeight(.semibold)) · \(item.action)")
    }
}
