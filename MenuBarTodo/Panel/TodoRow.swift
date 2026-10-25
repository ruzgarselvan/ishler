import SwiftUI
import TodoCore

struct TodoRow: View {
    let item: TodoItem
    let now: Date
    let calendar: Calendar
    var tint: Color? = nil
    let onDone: () -> Void
    let onEdit: () -> Void

    @State private var hovering = false
    @State private var completing = false

    var body: some View {
        let due = DueLabel(item: item, now: now, calendar: calendar)
        let ring = tint ?? Color.secondary
        HStack(spacing: 9) {
            Button(action: complete) {
                ZStack {
                    Circle().strokeBorder(ring.opacity(completing ? 1 : 0.65), lineWidth: 1.5)
                    if completing || hovering {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ring.opacity(completing ? 1 : 0.5))
                    }
                }
                .frame(width: 20, height: 20)
                .background(completing ? ring.opacity(0.18) : .clear, in: Circle())
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Yapıldı")

            HStack(spacing: 9) {
                label
                    .font(.system(size: 13))
                    .strikethrough(completing)
                    .foregroundStyle(completing ? .secondary : .primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let progress = checklistProgress(item) {
                    Text(progress).font(.system(size: 11)).foregroundStyle(.tertiary)
                }
                if item.repeatRule != nil {
                    Image(systemName: "repeat").font(.system(size: 9)).foregroundStyle(.tertiary)
                }
                Text(due.text)
                    .font(.system(size: 11))
                    .foregroundStyle(due.isOverdue ? Color.red : Color.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
            .help("Düzenle")
        }
        .padding(.vertical, 3).padding(.horizontal, 6)
        .background(hovering ? Color.primary.opacity(0.06) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, -6)
        .opacity(completing ? 0.5 : 1)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
        .animation(.easeOut(duration: 0.2), value: completing)
    }

    private func complete() {
        guard !completing else { return }
        completing = true
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            onDone()
        }
    }

    private var label: Text {
        guard let person = item.person else { return Text(item.action) }
        return Text("\(Text(person).fontWeight(.semibold)) · \(item.action)")
    }
}
