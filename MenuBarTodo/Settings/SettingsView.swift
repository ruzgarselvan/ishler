import SwiftUI
import TodoCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    let onBack: () -> Void

    var body: some View {
        @Bindable var store = model.settingsStore
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("‹ İşler", action: onBack).buttonStyle(.plain).foregroundStyle(Color.accentColor)
                Spacer()
                Text("Ayarlar").font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("‹ İşler").hidden()
            }
            Text("Bildirimler").font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            Stepper("Teslimden önce her akşam: \(store.settings.eveningDaysBefore) gün",
                    value: $store.settings.eveningDaysBefore, in: 0...7)
            timeRow("Akşam saati", $store.settings.eveningTime)
            timeRow("Teslim günü sabah", $store.settings.morningTime)
            timeRow("Tarihsiz/gecikmiş işler", $store.settings.digestTime)
        }
        .font(.system(size: 13))
        .onChange(of: store.settings) { Task { await model.reschedule() } }
    }

    private func timeRow(_ title: String, _ comps: Binding<DateComponents>) -> some View {
        let date = Binding<Date>(
            get: { Calendar.current.date(from: DateComponents(hour: comps.wrappedValue.hour, minute: comps.wrappedValue.minute)) ?? .now },
            set: { comps.wrappedValue = Calendar.current.dateComponents([.hour, .minute], from: $0) }
        )
        return DatePicker(title, selection: date, displayedComponents: .hourAndMinute)
    }
}
