import SwiftUI
import SwiftData
import TodoCore

@main
struct MenuBarTodoApp: App {
    @State private var model: AppModel

    init() {
        let store = try! TodoStore()
        _model = State(initialValue: AppModel(store: store))
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
