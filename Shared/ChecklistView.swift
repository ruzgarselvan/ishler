import SwiftUI
import TodoCore

/// Steps of an item with tick boxes; `editable` adds a field to add steps and a delete button per step.
struct ChecklistView: View {
    @Environment(AppModel.self) private var model
    let item: TodoItem
    var editable = false
    var compact = true
    @State private var newStep = ""

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            ForEach(item.checklist) { step in
                HStack(spacing: 8) {
                    Button { toggle(step) } label: {
                        Image(systemName: step.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(step.done ? Color.accentColor : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    Text(step.title)
                        .strikethrough(step.done)
                        .foregroundStyle(step.done ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if editable {
                        Button { remove(step) } label: { Image(systemName: "minus.circle").foregroundStyle(.secondary) }
                            .buttonStyle(.plain)
                    }
                }
            }
            if editable {
                TextField("Adım ekle", text: $newStep)
                    .textFieldStyle(.plain)
                    .onSubmit(add)
            }
        }
        .font(.system(size: compact ? 12 : 15))
    }

    private func toggle(_ step: ChecklistEntry) {
        item.checklist = item.checklist.map { $0.id == step.id ? ChecklistEntry(id: $0.id, title: $0.title, done: !$0.done) : $0 }
        model.save()
    }

    private func remove(_ step: ChecklistEntry) {
        item.checklist = item.checklist.filter { $0.id != step.id }
        model.save()
    }

    private func add() {
        let title = newStep.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        item.checklist = item.checklist + [ChecklistEntry(title: title)]
        newStep = ""
        model.save()
    }
}

/// "2/5" for items with steps.
func checklistProgress(_ item: TodoItem) -> String? {
    let steps = item.checklist
    return steps.isEmpty ? nil : "\(steps.filter(\.done).count)/\(steps.count)"
}
