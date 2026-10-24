import SwiftUI
import SwiftData
import TodoCore

struct PanelView: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [TodoItem]

    var body: some View {
        let now = Date()
        let groups = sortedOpenItems(items, now: now, calendar: model.calendar)
        VStack(alignment: .leading, spacing: 0) {
            EntryField()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(groups, id: \.0) { bucket, rows in
                        Text(bucketTitle(bucket))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.top, 14).padding(.bottom, 4).padding(.horizontal, 6)
                        ForEach(rows) { item in
                            TodoRow(item: item, now: now, calendar: model.calendar) { model.markDone(item) }
                            Divider().opacity(0.5)
                        }
                    }
                    if groups.isEmpty {
                        Text("Açık iş yok")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 30)
                    }
                }
            }
            .frame(maxHeight: 420)
        }
        .padding(14)
        .frame(width: 340)
    }
}
