import SwiftUI
import TodoCore

/// "Şimdi sadece bu": one item at a time. `items` is already in priority order.
struct FocusCard: View {
    @Environment(AppModel.self) private var model
    let items: [TodoItem]
    var compact = true
    @State private var skipped = 0

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 16) {
            if items.isEmpty {
                Text("Her şey yolunda").font(.system(size: compact ? 14 : 20, weight: .semibold))
                Text("Açık iş kalmadı.").foregroundStyle(.secondary)
            } else {
                let item = items[skipped % items.count]
                let due = DueLabel(item: item, now: Date(), calendar: model.calendar)
                Text("Şimdi sadece bu").font(.system(size: compact ? 11 : 14)).foregroundStyle(.secondary)
                itemLabel(item)
                    .font(.system(size: compact ? 18 : 28))
                    .fixedSize(horizontal: false, vertical: true)
                Text(due.text).foregroundStyle(due.isOverdue ? Color.red : Color.secondary)
                    .font(.system(size: compact ? 12 : 17))
                if !item.checklist.isEmpty { ChecklistView(item: item, compact: compact) }
                HStack {
                    if items.count > 1 {
                        Button("Sonraki") { skipped += 1 }.buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Yapıldı") { model.markDone(item) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(compact ? .small : .large)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
