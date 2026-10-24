import SwiftUI
import SwiftData
import TodoCore

@main
struct PhoneApp: App {
    @State private var model: AppModel

    init() {
        let model = AppModel(store: try! TodoStore())
        _model = State(initialValue: model)
        Task { await model.start() }
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
    var body: some View {
        TabView {
            Tab("İşler", systemImage: "checklist") { TodayScreen() }
            Tab("Takvim", systemImage: "calendar") { CalendarScreen() }
            Tab("Arşiv", systemImage: "archivebox") { ArchiveScreen() }
            Tab("Ayarlar", systemImage: "gearshape") { SettingsScreen() }
        }
    }
}
