import SwiftUI
import TodoCore

struct SettingsScreen: View {
    @Environment(AppModel.self) private var model
    @State private var exportURL: URL?

    var body: some View {
        @Bindable var store = model.settingsStore
        NavigationStack {
            Form {
                Section {
                    Picker("Liste", selection: $store.horizon) {
                        Text("1 hafta").tag(Horizon.week)
                        Text("1 ay").tag(Horizon.month)
                        Text("Hepsi").tag(Horizon.all)
                    }
                    .pickerStyle(.segmented)
                } header: { Text("Liste") } footer: { Text("Gecikmiş ve tarihsiz işler her zaman görünür.") }

                Section("Kategoriler") { CategoryEditor(store: store) }

                Section("Şablonlar") { TemplateEditor(store: store) }

                Section {
                    Picker("Gün", selection: $store.settings.eveningDaysBefore) {
                        Text("Yok").tag(0)
                        ForEach([1, 2, 3, 5, 7], id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: { Text("Hatırlatıcı") } footer: {
                    Text(footnote(store))
                }

                Section("Takvim ve yedek") {
                    Toggle("Apple Takvim'e yaz", isOn: $store.writeToCalendar)
                    if let url = exportURL {
                        ShareLink(item: url) { Label("İşleri CSV olarak dışa aktar", systemImage: "square.and.arrow.up") }
                    }
                }

                Section("Görünüm") {
                    Picker("Görünüm", selection: $store.appearance) {
                        Text("Sistem").tag(Appearance.system)
                        Text("Açık").tag(Appearance.light)
                        Text("Koyu").tag(Appearance.dark)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Ayarlar")
            .onAppear { exportURL = model.makeExport() }
            .onChange(of: store.writeToCalendar) { Task { await model.reschedule() } }
            .onChange(of: store.settings) { Task { await model.reschedule() } }
            .onChange(of: store.categories) { Task { await model.reschedule() } }
        }
    }

    private func footnote(_ store: SettingsStore) -> LocalizedStringKey {
        if store.reminderCategoryIDs.isEmpty { return "Hatırlatma kapalı. Kategorilerden zili açarak başlat." }
        let days = store.settings.eveningDaysBefore
        return days == 0 ? "Zili açık kategorilerde teslim günü sabah bildirim gelir."
                         : "Zili açık kategorilerde son \(days) gün her akşam, teslim günü sabah bildirim gelir."
    }
}
