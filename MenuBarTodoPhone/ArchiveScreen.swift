import SwiftUI
import SwiftData
import TodoCore

struct ArchiveScreen: View {
    @Environment(AppModel.self) private var model
    @Query(filter: #Predicate<TodoItem> { $0.doneAt != nil }, sort: \TodoItem.doneAt, order: .reverse)
    private var items: [TodoItem]

    var body: some View {
        NavigationStack {
            List(items) { item in
                Button { model.reopen(item) } label: {
                    HStack {
                        itemLabel(item).strikethrough().lineLimit(1)
                        Spacer()
                        Text((item.doneAt ?? .now).formatted(.dateTime.day().month(.abbreviated).locale(appLocale)))
                            .font(.subheadline).foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.secondary)
                }
                .swipeActions { Button("Geri aç", systemImage: "arrow.uturn.backward") { model.reopen(item) } }
            }
            .overlay {
                if items.isEmpty { ContentUnavailableView("Arşiv boş", systemImage: "archivebox") }
            }
            .navigationTitle("Arşiv")
        }
    }
}
