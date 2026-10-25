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
        .padding(.horizontal, 14).padding(.top, 12).padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
        .frame(width: 320, height: 500)
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

    private var tabBar: some View {
        HStack(spacing: 0) {
            tab("checklist", "İşler", on: { if case .list = screen { true } else { false } }()) { screen = .list }
            tab("scope", "Odak", on: { if case .focus = screen { true } else { false } }()) { screen = .focus }
            tab("calendar", "Takvim", on: { if case .calendar = screen { true } else { false } }()) { screen = .calendar }
            tab("archivebox", "Arşiv", on: { if case .archive = screen { true } else { false } }()) { screen = .archive }
            tab("gearshape", "Ayarlar", on: { if case .settings = screen { true } else { false } }()) { screen = .settings }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .contextMenu { Button("ishler'dan çık") { NSApplication.shared.terminate(nil) } }
    }

    private func tab(_ symbol: String, _ title: LocalizedStringKey, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbol).font(.system(size: 16, weight: .medium))
                Text(title).font(.system(size: 10))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 5)
            .foregroundStyle(on ? Color.accentColor : Color.secondary)
            .background(on ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var list: some View {
        let now = Date()
        let visible = items.filter { isVisible($0, horizon: model.settingsStore.horizon, now: now, calendar: model.calendar) }
        let groups = sortedOpenItems(visible, now: now, calendar: model.calendar)
        return VStack(alignment: .leading, spacing: 6) {
            EntryField()
            if !groups.isEmpty {
                FittedScroll(maxHeight: 360) {
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
            if groups.isEmpty {
                Text("Açık iş yok").font(.system(size: 13)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.top, 60)
            }
        }
    }
}
