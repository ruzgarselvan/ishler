import SwiftUI
import TodoCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let onBack: () -> Void

    var body: some View {
        @Bindable var store = model.settingsStore
        VStack(alignment: .leading, spacing: 14) {
            PanelHeader(title: "Ayarlar", onBack: onBack)

            section("Listede göster", footnote: "Gecikmiş ve tarihsiz işler her zaman görünür.") {
                Picker("", selection: $store.horizon) {
                    Text("1 hafta").tag(Horizon.week)
                    Text("1 ay").tag(Horizon.month)
                    Text("Hepsi").tag(Horizon.all)
                }
            }

            section("Teslimden kaç gün önce hatırlat", footnote: footnote(store.settings.eveningDaysBefore)) {
                Picker("", selection: $store.settings.eveningDaysBefore) {
                    Text("Yok").tag(0)
                    ForEach([1, 2, 3, 5, 7], id: \.self) { Text("\($0)").tag($0) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .onChange(of: store.settings) { Task { await model.reschedule() } }
    }

    private func footnote(_ days: Int) -> String {
        days == 0 ? "Sadece teslim günü sabah bildirim gelir."
                  : "Son \(days) gün her akşam, teslim günü sabah bildirim gelir."
    }

    private func section(_ title: String, footnote: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 12, weight: .semibold))
            content().pickerStyle(.segmented).labelsHidden().controlSize(.small)
            Text(footnote).font(.system(size: 11)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
