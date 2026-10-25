import SwiftUI
import TodoCore

struct EditView: View {
    @Environment(AppModel.self) private var model
    let item: TodoItem
    let onClose: () -> Void

    @State private var person: String
    @State private var action: String
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var categoryID: UUID?

    init(item: TodoItem, onClose: @escaping () -> Void) {
        self.item = item
        self.onClose = onClose
        _person = State(initialValue: item.person ?? "")
        _action = State(initialValue: item.action)
        _hasDate = State(initialValue: item.dueDate != nil)
        _date = State(initialValue: item.dueDate ?? Date())
        _hasTime = State(initialValue: item.dueMinutes != nil)
        let minutes = item.dueMinutes ?? 9 * 60
        _time = State(initialValue: Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date())
        _categoryID = State(initialValue: item.categoryID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelHeader(title: "İşi düzenle", onBack: onClose)
            FittedScroll(maxHeight: 380) {
                VStack(alignment: .leading, spacing: 10) {
                    field("Kişi", text: $person)
                    field("İş", text: $action)
                    if !model.settingsStore.categories.isEmpty {
                        CategoryMenu(categories: model.settingsStore.categories, selection: $categoryID)
                            .font(.system(size: 12))
                    }
                    HStack {
                        Toggle("Tarih", isOn: $hasDate).toggleStyle(.switch).controlSize(.small)
                        Spacer()
                        if hasDate {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden().datePickerStyle(.compact)
                                .environment(\.locale, appLocale)
                        }
                    }
                    if hasDate {
                        HStack {
                            Toggle("Saat", isOn: $hasTime).toggleStyle(.switch).controlSize(.small)
                            Spacer()
                            if hasTime {
                                DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                                    .labelsHidden().datePickerStyle(.compact)
                            }
                        }
                    }
                    if item.repeatRule != nil {
                        HStack {
                            Label("Tekrarlıyor", systemImage: "repeat").foregroundStyle(.secondary)
                            Spacer()
                            Button("Tekrarı kaldır") { item.repeatRule = nil; model.save() }
                                .buttonStyle(.plain).foregroundStyle(Color.accentColor)
                        }
                        .font(.system(size: 12))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Adımlar").font(.system(size: 11)).foregroundStyle(.secondary)
                        ChecklistView(item: item, editable: true)
                    }
                }
                .padding(.horizontal, 4)
                .font(.system(size: 12))
            }
            HStack {
                Button("Sil", role: .destructive) { model.delete(item); onClose() }
                    .buttonStyle(.plain).foregroundStyle(.red).font(.system(size: 12))
                Spacer()
                Button("Kaydet", action: save)
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    .keyboardShortcut(.defaultAction)
                    .disabled(action.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 4)
        }
        .padding(.bottom, 4)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 11)).foregroundStyle(.secondary)
            TextField("", text: text)
                .textFieldStyle(.plain).font(.system(size: 13))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
        }
    }

    private func save() {
        let due = hasDate ? model.calendar.startOfDay(for: date) : nil
        let minutes = hasDate && hasTime
            ? Calendar.current.component(.hour, from: time) * 60 + Calendar.current.component(.minute, from: time) : nil
        if model.update(item, person: person, action: action, dueDate: due, dueMinutes: minutes, categoryID: categoryID) { onClose() }
    }
}
