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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("‹ İşler", action: onBack).buttonStyle(.plain).foregroundStyle(Color.accentColor)
                Spacer()
                Text("Arşiv").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("‹ İşler").hidden()
            }
            TextField("Arşivde ara…", text: $query)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(shown) { item in
                        Button { model.reopen(item) } label: {
                            HStack {
                                label(item)
                                Spacer()
                                Text((item.doneAt ?? .now).formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "tr_TR"))))
                                    .foregroundStyle(.secondary)
                            }
                            .font(.system(size: 12))
                            .strikethrough()
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help("Geri aç")
                    }
                    if shown.isEmpty {
                        Text("Arşiv boş").foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.vertical, 30)
                    }
                }
            }
            .frame(maxHeight: 420)
        }
    }

    private func label(_ item: TodoItem) -> Text {
        guard let person = item.person else { return Text(item.action) }
        return Text("\(Text(person).fontWeight(.semibold)) · \(item.action)")
    }
}
