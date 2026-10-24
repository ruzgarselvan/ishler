import SwiftUI
import TodoCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let onBack: () -> Void
    @State private var launchAtLogin = false
    @State private var exportURL: URL?

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

                    section("Kategoriler", footnote: nil) {
                        CategoryEditor(store: store, compact: true)
                    }

                    section("Düzenli işler", footnote: nil) {
                        RoutineEditor(store: store, compact: true)
                    }

                    section("Hatırlatıcı", footnote: footnote(store)) {
                        Picker("", selection: $store.settings.eveningDaysBefore) {
                            Text("Yok").tag(0)
                            ForEach([1, 2, 3, 5, 7], id: \.self) { Text("\($0)").tag($0) }
                        }
                        .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                    }

                    section("Menü bar", footnote: nil) {
                        Picker("", selection: $store.menuBarStyle) {
                            Text("Sayı").tag(MenuBarStyle.count)
                            Text("Sıradaki iş").tag(MenuBarStyle.title)
                            Text("Yok").tag(MenuBarStyle.off)
                        }
                        .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                    }

                    section("Görünüm", footnote: nil) {
                        Picker("", selection: $store.appearance) {
                            Text("Sistem").tag(Appearance.system)
                            Text("Açık").tag(Appearance.light)
                            Text("Koyu").tag(Appearance.dark)
                        }
                        .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                    }

                    section("Yedek", footnote: nil) {
                        if let url = exportURL {
                            ShareLink(item: url) { Label("İşleri CSV olarak dışa aktar", systemImage: "square.and.arrow.up") }
                                .buttonStyle(.plain).foregroundStyle(Color.accentColor).font(.system(size: 12))
                        }
                    }

                    section("Genel", footnote: nil) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Girişte otomatik başlat", isOn: $launchAtLogin)
                            Toggle("Apple Takvim'e yaz", isOn: $store.writeToCalendar)
                            Toggle("Hızlı ekle kısayolu (⌃⌥N)", isOn: $store.quickAddHotkey)
                        }
                        .toggleStyle(.switch).controlSize(.small).font(.system(size: 12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
        }
        .padding(.bottom, 4)
        .onAppear { launchAtLogin = model.launchAtLogin; exportURL = model.makeExport() }
        .onChange(of: launchAtLogin) { model.launchAtLogin = launchAtLogin }
        .onChange(of: store.menuBarStyle) { model.refreshBadge() }
        .onChange(of: store.quickAddHotkey) { QuickAdd.shared.setEnabled(store.quickAddHotkey) }
        .onChange(of: store.writeToCalendar) { Task { await model.reschedule() } }
        .onChange(of: store.templates) { }
        .onChange(of: store.appearance) { model.applyAppearance() }
        .onChange(of: store.settings) { Task { await model.reschedule() } }
        .onChange(of: store.categories) { Task { await model.reschedule() } }
    }

    private func footnote(_ store: SettingsStore) -> LocalizedStringKey {
        if store.reminderCategoryIDs.isEmpty { return "Hatırlatma kapalı. Kategorilerden zili açarak başlat." }
        let days = store.settings.eveningDaysBefore
        return days == 0 ? "Zili açık kategorilerde teslim günü sabah bildirim gelir."
                         : "Zili açık kategorilerde son \(days) gün her akşam, teslim günü sabah bildirim gelir."
    }

    private func section(_ title: LocalizedStringKey, footnote: LocalizedStringKey?, @ViewBuilder content: () -> some View) -> some View {
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
