import SwiftUI
import SwiftData
import TodoCore

struct PanelView: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [TodoItem]
    @State private var screen: Screen = .list

    enum Screen { case list, archive, settings }

    var body: some View {
        Group {
            switch screen {
            case .list: list
            case .archive: ArchiveView { screen = .list }
            case .settings: SettingsView { screen = .list }
            }
        }
        .padding(10)
        .frame(width: 300)
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
                                TodoRow(item: item, now: now, calendar: model.calendar) { model.markDone(item) }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            HStack(spacing: 12) {
                Text(groups.isEmpty ? "Açık iş yok" : "\(visible.filter { !$0.isDone }.count) açık iş")
                Spacer()
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
