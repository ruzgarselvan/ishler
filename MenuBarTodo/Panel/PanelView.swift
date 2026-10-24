import SwiftUI
import SwiftData
import TodoCore

struct PanelView: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [TodoItem]
    @State private var screen: Screen = .list

    enum Screen { case list, archive, settings, calendar, focus, edit(TodoItem) }

    var body: some View {
        Group {
            switch screen {
            case .list: list
            case .archive: ArchiveView { screen = .list }
            case .focus: focusScreen
            case .calendar: CalendarView(onBack: { screen = .list }, onEdit: { screen = .edit($0) })
            case .settings: SettingsView { screen = .list }
            case .edit(let item): EditView(item: item) { screen = .list }
            }
        }
        .padding(10)
        .frame(width: 300)
        .onAppear { model.refreshBadge(); model.touch() }
        .onDisappear { screen = .list }
    }

    private var focusScreen: some View {
        let now = Date()
        let visible = items.filter { isVisible($0, horizon: model.settingsStore.horizon, now: now, calendar: model.calendar) }
        let ordered = sortedOpenItems(visible, now: now, calendar: model.calendar).flatMap(\.1)
        return VStack(alignment: .leading, spacing: 10) {
            PanelHeader(title: "Odak", onBack: { screen = .list })
            FocusCard(items: ordered).padding(.horizontal, 4)
        }
    }

    private var list: some View {
        let now = Date()
        let visible = items.filter { isVisible($0, horizon: model.settingsStore.horizon, now: now, calendar: model.calendar) }
        let groups = sortedOpenItems(visible, now: now, calendar: model.calendar)
        return VStack(alignment: .leading, spacing: 6) {
            EntryField()
            if !groups.isEmpty {
                FittedScroll(maxHeight: 460) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(groups, id: \.0) { bucket, rows in
                            Text(bucketTitle(bucket))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.top, 8).padding(.bottom, 1)
                            ForEach(rows) { item in
                                TodoRow(item: item, now: now, calendar: model.calendar, tint: model.color(for: item), onDone: { model.markDone(item) }, onEdit: { screen = .edit(item) })
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            HStack(spacing: 12) {
                Text(groups.isEmpty ? LocalizedStringKey("Açık iş yok") : LocalizedStringKey("\(visible.filter { !$0.isDone }.count) açık iş"))
                Spacer()
                Button { screen = .focus } label: { Image(systemName: "scope") }.help("Şimdi sadece bu")
                Button { screen = .calendar } label: { Image(systemName: "calendar") }.help("Takvim")
                Button { screen = .archive } label: { Image(systemName: "archivebox") }.help("Arşiv")
                Button { screen = .settings } label: { Image(systemName: "gearshape") }.help("Ayarlar")
                Button { NSApplication.shared.terminate(nil) } label: { Image(systemName: "power") }.help("Çık")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }
}
