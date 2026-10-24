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
            model.applyAppMode()
            QuickAdd.shared.setEnabled(model.settingsStore.quickAddHotkey)
            await model.start()
        }
    }

    var body: some Scene {
        MenuBarExtra(isInserted: Binding(get: { model.settingsStore.appMode.showsMenuBarIcon }, set: { _ in })) {
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

        // The normal-app window, used when the app is set to live in the Dock.
        Window("ishler", id: "main") {
            PanelView()
                .environment(model)
                .modelContainer(model.store.container)
                .onAppear { if !model.settingsStore.appMode.showsDockIcon { closeMainWindow() } }
        }
        .windowResizability(.contentSize)
    }

    private func closeMainWindow() {
        DispatchQueue.main.async { NSApp.windows.first { $0.title == "ishler" }?.close() }
    }
}
