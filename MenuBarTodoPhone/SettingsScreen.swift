import SwiftUI
import TodoCore

struct SettingsScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var store = model.settingsStore
        NavigationStack {
            Form {
                Section {
                    Picker("Listede göster", selection: $store.horizon) {
                        Text("1 hafta").tag(Horizon.week)
                        Text("1 ay").tag(Horizon.month)
                        Text("Hepsi").tag(Horizon.all)
                    }
                    .pickerStyle(.segmented)
                } header: { Text("Listede göster") } footer: { Text("Gecikmiş ve tarihsiz işler her zaman görünür.") }

                Section {
                    Picker("Gün", selection: $store.settings.eveningDaysBefore) {
                        Text("Yok").tag(0)
                        ForEach([1, 2, 3, 5, 7], id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: { Text("Teslimden kaç gün önce hatırlat") } footer: {
                    Text(store.reminderCategoryIDs.isEmpty
                         ? "Hatırlatma kapalı. Kategorilerden zili açarak başlat."
                         : store.settings.eveningDaysBefore == 0
                           ? "Zili açık kategorilerde teslim günü sabah bildirim gelir."
                           : "Zili açık kategorilerde son \(store.settings.eveningDaysBefore) gün her akşam, teslim günü sabah bildirim gelir.")
                }

                Section("Kategoriler") { CategoryEditor(store: store) }
            }
            .navigationTitle("Ayarlar")
            .onChange(of: store.settings) { Task { await model.reschedule() } }
            .onChange(of: store.categories) { Task { await model.reschedule() } }
        }
    }
}
