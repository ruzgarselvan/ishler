import SwiftUI
import TodoCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let onBack: () -> Void
    @State private var launchAtLogin = false

    var body: some View {
        @Bindable var store = model.settingsStore
        VStack(alignment: .leading, spacing: 10) {
            PanelHeader(title: "Ayarlar", onBack: onBack)
            FittedScroll(maxHeight: 440) {
                VStack(alignment: .leading, spacing: 16) {
                    section("Liste", footnote: "Gecikmiş ve tarihsiz işler her zaman görünür.") {
                        Picker("", selection: $store.horizon) {
                            Text("1 hafta").tag(Horizon.week)
                            Text("1 ay").tag(Horizon.month)
                            Text("Hepsi").tag(Horizon.all)
                        }
                        .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                    }

                    section("Hatırlatıcı", footnote: footnote(store)) {
                        Picker("", selection: $store.settings.eveningDaysBefore) {
                            Text("Yok").tag(0)
                            ForEach([1, 2, 3, 5, 7], id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                    }

                    section("Kategoriler", footnote: nil) {
                        CategoryEditor(store: store, compact: true)
                    }

                    section("Genel", footnote: nil) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Girişte otomatik başlat", isOn: $launchAtLogin)
                            Toggle("Menü bar'da bugünkü işleri say", isOn: $store.showBadge)
                        }
                        .toggleStyle(.switch).controlSize(.small).font(.system(size: 12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
        }
        .padding(.bottom, 4)
        .onAppear { launchAtLogin = model.launchAtLogin }
        .onChange(of: launchAtLogin) { model.launchAtLogin = launchAtLogin }
        .onChange(of: store.showBadge) { model.refreshBadge() }
        .onChange(of: store.settings) { Task { await model.reschedule() } }
        .onChange(of: store.categories) { Task { await model.reschedule() } }
    }

    private func footnote(_ store: SettingsStore) -> String {
        if store.reminderCategoryIDs.isEmpty { return "Hatırlatma kapalı. Kategorilerden zili açarak başlat." }
        let days = store.settings.eveningDaysBefore
        return days == 0 ? "Zili açık kategorilerde teslim günü sabah bildirim gelir."
                         : "Zili açık kategorilerde son \(days) gün her akşam, teslim günü sabah bildirim gelir."
    }

    private func section(_ title: String, footnote: String?, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 12, weight: .semibold))
            content()
            if let footnote {
                Text(footnote).font(.system(size: 11)).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
