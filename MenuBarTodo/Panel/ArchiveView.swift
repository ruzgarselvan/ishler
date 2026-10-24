import SwiftUI
import SwiftData
import TodoCore

struct ArchiveView: View {
    @Environment(AppModel.self) private var model
    @Query(filter: #Predicate<TodoItem> { $0.doneAt != nil }, sort: \TodoItem.doneAt, order: .reverse)
    private var items: [TodoItem]
    @State private var query = ""
    let onBack: () -> Void

    private var shown: [TodoItem] {
        guard !query.isEmpty else { return items }
        return items.filter { "\($0.person ?? "") \($0.action)".localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PanelHeader(title: "Arşiv", onBack: onBack)
            if items.count > 8 {
                TextField("Ara", text: $query)
                    .textFieldStyle(.plain).font(.system(size: 12))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            }
            if shown.isEmpty {
                Text("Arşiv boş").font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
            } else {
                FittedScroll(maxHeight: 460) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(shown) { item in
                            Button { model.reopen(item) } label: {
                                HStack {
                                    label(item).lineLimit(1)
                                    Spacer()
                                    Text((item.doneAt ?? .now).formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "tr_TR"))))
                                        .foregroundStyle(.tertiary)
                                }
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 2)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("Geri aç")
                        }
                    }
                }
            }
        }
    }

    private func label(_ item: TodoItem) -> Text {
        guard let person = item.person else { return Text(item.action) }
        return Text("\(Text(person).fontWeight(.semibold)) · \(item.action)")
    }
}
