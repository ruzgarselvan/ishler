import SwiftUI
import TodoCore

struct EditSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let item: TodoItem

    @State private var person: String
    @State private var action: String
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var time: Date
    @State private var categoryID: UUID?

    init(item: TodoItem) {
        self.item = item
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
        NavigationStack {
            Form {
                Section {
                    TextField("Kişi", text: $person).autocorrectionDisabled()
                    TextField("İş", text: $action).autocorrectionDisabled()
                    if !model.settingsStore.categories.isEmpty {
                        CategoryMenu(categories: model.settingsStore.categories, selection: $categoryID)
                    }
                }
                Section {
                    Toggle("Tarih", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Gün", selection: $date, displayedComponents: .date)
                            .environment(\.locale, appLocale)
                        Toggle("Saat", isOn: $hasTime)
                        if hasTime { DatePicker("Saat", selection: $time, displayedComponents: .hourAndMinute) }
                    }
                    if item.repeatRule != nil {
                        Button("Tekrarı kaldır") { item.repeatRule = nil; model.save() }
                    }
                }
                Section("Adımlar") { ChecklistView(item: item, editable: true, compact: false) }
                Section {
                    Button("Sil", role: .destructive) { model.delete(item); dismiss() }
                }
            }
            .navigationTitle("İşi düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet", action: save)
                        .disabled(action.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let due = hasDate ? model.calendar.startOfDay(for: date) : nil
        let minutes = hasDate && hasTime
            ? Calendar.current.component(.hour, from: time) * 60 + Calendar.current.component(.minute, from: time) : nil
        if model.update(item, person: person, action: action, dueDate: due, dueMinutes: minutes, categoryID: categoryID) { dismiss() }
    }
}
