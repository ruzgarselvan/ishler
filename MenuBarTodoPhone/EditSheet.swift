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

    init(item: TodoItem) {
        self.item = item
        _person = State(initialValue: item.person ?? "")
        _action = State(initialValue: item.action)
        _hasDate = State(initialValue: item.dueDate != nil)
        _date = State(initialValue: item.dueDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Kişi", text: $person).autocorrectionDisabled()
                    TextField("İş", text: $action).autocorrectionDisabled()
                }
                Section {
                    Toggle("Tarih", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Gün", selection: $date, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "tr_TR"))
                    }
                }
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
        .presentationDetents([.medium])
    }

    private func save() {
        let due = hasDate ? model.calendar.startOfDay(for: date) : nil
        if model.update(item, person: person, action: action, dueDate: due) { dismiss() }
    }
}
