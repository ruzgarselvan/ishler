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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            Tab("İşler", systemImage: "checklist") { TodayScreen() }
            Tab("Takvim", systemImage: "calendar") { CalendarScreen() }
            Tab("Arşiv", systemImage: "archivebox") { ArchiveScreen() }
            Tab("Ayarlar", systemImage: "gearshape") { SettingsScreen() }
        }
        .preferredColorScheme(model.colorScheme)
        .onChange(of: scenePhase) { if scenePhase == .active { model.touch() } }
    }
}
