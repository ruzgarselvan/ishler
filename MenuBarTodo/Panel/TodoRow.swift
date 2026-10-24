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
            label
                .font(.system(size: 14))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(due.text)
                .font(.system(size: 12))
                .foregroundStyle(due.isOverdue ? Color.red : Color.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
    }

    private var label: Text {
        guard let person = item.person else { return Text(item.action) }
        return Text("\(Text(person).fontWeight(.semibold)) · \(item.action)")
    }
}
