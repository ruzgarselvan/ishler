import SwiftUI
import SwiftData
import TodoCore

@main
struct MenuBarTodoApp: App {
    @State private var model = AppModel.shared

    init() {
        let model = AppModel.shared
        Task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-demoWindow") {
                if ProcessInfo.processInfo.arguments.contains("-demoDark") { NSApp.appearance = NSAppearance(named: .darkAqua) }
                else { NSApp.appearance = NSAppearance(named: .aqua) }
                DemoWindow.show(model: model)
            }
            #endif
            QuickAdd.shared.setEnabled(model.settingsStore.quickAddHotkey)
            await model.start()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PanelView()
                .environment(model)
                .modelContainer(model.store.container)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "checklist")
                switch model.settingsStore.menuBarStyle {
                case .count: if model.badgeCount > 0 { Text("\(model.badgeCount)") }
                case .title: if !model.nextItemText.isEmpty { Text(model.nextItemText) }
                case .off: EmptyView()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
