import SwiftUI
import SwiftData
import TodoCore

@main
struct PhoneApp: App {
    @State private var model = AppModel.shared

    init() {
        Task { await AppModel.shared.start() }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .modelContainer(model.store.container)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    #if DEBUG
    /// `-startTab 1|2|3` opens that tab at launch (for store screenshots).
    @State private var selection = ProcessInfo.processInfo.arguments.drop(while: { $0 != "-startTab" }).dropFirst().first.flatMap(Int.init) ?? 0
    #else
    @State private var selection = 0
    #endif
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selection) {
            Tab("İşler", systemImage: "checklist", value: 0) { TodayScreen() }
            Tab("Takvim", systemImage: "calendar", value: 1) { CalendarScreen() }
            Tab("Arşiv", systemImage: "archivebox", value: 2) { ArchiveScreen() }
            Tab("Ayarlar", systemImage: "gearshape", value: 3) { SettingsScreen() }
        }
        .preferredColorScheme(model.colorScheme)
        .onChange(of: scenePhase) { if scenePhase == .active { model.touch() } }
    }
}
