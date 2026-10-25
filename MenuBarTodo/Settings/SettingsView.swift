import SwiftUI
import SwiftData
import TodoCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let onBack: () -> Void
    @State private var launchAtLogin = false
    @State private var exportURL: URL?
    @State private var confirmClear = false
    @State private var confirmClearAll = false
    @Query private var allItems: [TodoItem]
    @Query(filter: #Predicate<TodoItem> { $0.doneAt != nil }) private var archived: [TodoItem]

    var body: some View {
        @Bindable var store = model.settingsStore
        VStack(alignment: .leading, spacing: 10) {
            PanelHeader(title: "Ayarlar", onBack: onBack)
            FittedScroll(maxHeight: 380) {
                VStack(alignment: .leading, spacing: 14) {
                    section("Liste ve hatırlatıcı") {
                        row("Liste") {
                            Picker("", selection: $store.horizon) {
                                Text("1 hafta").tag(Horizon.week)
                                Text("1 ay").tag(Horizon.month)
                                Text("Hepsi").tag(Horizon.all)
                            }
                            .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                        }
                        note("Gecikmiş ve tarihsiz işler her zaman görünür.")
                        Divider()
                        row("Hatırlatıcı (gün)") {
                            Picker("", selection: $store.settings.eveningDaysBefore) {
                                Text("Yok").tag(0)
                                ForEach([1, 2, 3, 5, 7], id: \.self) { Text("\($0)").tag($0) }
                            }
                            .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                        }
                        note(footnote(store))
                    }

                    section("Kategoriler") {
                        CategoryEditor(store: store, compact: true)
                    }

                    section("Düzenli işler") {
                        RoutineEditor(store: store, compact: true)
                    }

                    section("Uygulama") {
                        row("Yer") {
                            Picker("", selection: $store.appMode) {
                                Text("Menü bar").tag(AppMode.menuBar)
                                Text("Dock").tag(AppMode.dock)
                                Text("İkisi").tag(AppMode.both)
                            }
                            .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                        }
                        Divider()
                        row("Menü bar") {
                            Picker("", selection: $store.menuBarStyle) {
                                Text("Sayı").tag(MenuBarStyle.count)
                                Text("Sıradaki iş").tag(MenuBarStyle.title)
                                Text("Yok").tag(MenuBarStyle.off)
                            }
                            .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                        }
                        Divider()
                        row("Görünüm") {
                            Picker("", selection: $store.appearance) {
                                Text("Sistem").tag(Appearance.system)
                                Text("Açık").tag(Appearance.light)
                                Text("Koyu").tag(Appearance.dark)
                            }
                            .pickerStyle(.segmented).labelsHidden().controlSize(.small)
                        }
                        Divider()
                        Toggle("Girişte otomatik başlat", isOn: $launchAtLogin)
                        Toggle("Apple Takvim'e yaz", isOn: $store.writeToCalendar)
                        Toggle("Hızlı ekle kısayolu (⌃⌥N)", isOn: $store.quickAddHotkey)
                    }

                    section("Veri") {
                        if let url = exportURL {
                            ShareLink(item: url) { Label("İşleri CSV olarak dışa aktar", systemImage: "square.and.arrow.up") }
                                .buttonStyle(.plain).foregroundStyle(Color.accentColor)
                            Divider()
                        }
                        deleteRow("Arşivi sıfırla (\(archived.count))", "Arşivdeki tüm işler silinsin mi?", symbol: "trash", count: archived.count, armed: $confirmClear) {
                            model.delete(archived)
                        }
                        Divider()
                        deleteRow("Tüm işleri sil (\(allItems.count))", "Açık ve arşivdeki tüm işler ve Takvim etkinlikleri silinsin mi?", symbol: "trash.fill", count: allItems.count, armed: $confirmClearAll) {
                            model.delete(allItems)
                        }
                        Divider()
                        HStack { Text("iCloud"); Spacer(); Text(model.iCloudStatus).foregroundStyle(.secondary) }
                    }

                    HStack {
                        Text("ishler \(AppModel.versionText)").foregroundStyle(.tertiary)
                        Spacer()
                        Button("ishler'dan çık") { NSApplication.shared.terminate(nil) }
                    }
                    .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2).padding(.bottom, 14)
            }
        }
        .padding(.bottom, 4)
        .onAppear { launchAtLogin = model.launchAtLogin; exportURL = model.makeExport() }
        .onChange(of: launchAtLogin) { model.launchAtLogin = launchAtLogin }
        .onChange(of: store.menuBarStyle) { model.refreshBadge() }
        .onChange(of: store.appMode) { model.applyAppMode() }
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

    private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).padding(.leading, 4)
            VStack(alignment: .leading, spacing: 8) { content() }
                .font(.system(size: 12))
                .toggleStyle(.switch).controlSize(.small)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    /// Two-step delete shown inline; system dialogs don't present reliably from a menu bar panel.
    private func deleteRow(_ title: LocalizedStringKey, _ question: LocalizedStringKey, symbol: String, count: Int, armed: Binding<Bool>, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if armed.wrappedValue {
                Text(question).fixedSize(horizontal: false, vertical: true)
                Text("Bu işlem geri alınamaz.").font(.system(size: 11)).foregroundStyle(.secondary)
                HStack {
                    Button("Vazgeç") { armed.wrappedValue = false }.buttonStyle(.bordered)
                    Button("Sil", role: .destructive) { action(); armed.wrappedValue = false }.buttonStyle(.borderedProminent).tint(.red)
                }
                .controlSize(.regular)
            } else {
                Button { armed.wrappedValue = true } label: {
                    Label(title, systemImage: symbol).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundStyle(count == 0 ? Color.secondary : Color.red)
                .disabled(count == 0)
            }
        }
    }

    private func row(_ label: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).foregroundStyle(.secondary).font(.system(size: 11))
            content()
        }
    }

    private func note(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }
}
