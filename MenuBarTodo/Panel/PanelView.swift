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
        .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 10)
        .frame(width: 320)
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

    private func footerButton(_ symbol: String, help: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol).font(.system(size: 14, weight: .medium)) }
            .buttonStyle(IconButtonStyle(size: 30))
            .help(help)
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
            HStack(spacing: 2) {
                Text(groups.isEmpty ? LocalizedStringKey("Açık iş yok") : LocalizedStringKey("\(visible.filter { !$0.isDone }.count) açık iş"))
                    .font(.system(size: 12))
                Spacer()
                footerButton("scope", help: "Şimdi sadece bu") { screen = .focus }
                footerButton("calendar", help: "Takvim") { screen = .calendar }
                footerButton("archivebox", help: "Arşiv") { screen = .archive }
                footerButton("gearshape", help: "Ayarlar") { screen = .settings }
                Menu {
                    Button("ishler'dan çık") { NSApplication.shared.terminate(nil) }
                } label: {
                    Image(systemName: "power").font(.system(size: 14, weight: .medium)).frame(width: 30, height: 30).contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton).menuIndicator(.hidden)
                .fixedSize()
                .help("Çık")
            }
            .foregroundStyle(.secondary)
            .padding(.top, 6)
        }
    }
}
