import SwiftUI
import SwiftData
import TodoCore

@main
struct MenuBarTodoApp: App {
    @State private var model: AppModel

    init() {
        let store = try! TodoStore()
        let model = AppModel(store: store)
        _model = State(initialValue: model)
        Task { await model.start() }
    }

    var body: some Scene {
        MenuBarExtra("İşler", systemImage: "checklist") {
            PanelView()
                .environment(model)
                .modelContainer(model.store.container)
        }
        .menuBarExtraStyle(.window)
    }
}
