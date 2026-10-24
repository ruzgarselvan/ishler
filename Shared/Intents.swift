import AppIntents
import TodoCore

struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "İş ekle"
    static let description = IntentDescription("Cümleyle yeni iş ekler, örneğin \"Cuma Deniz'i ara 14:00\".")

    @Parameter(title: "İş", requestValueDialog: "Ne ekleyeyim?")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let item = AppModel.shared.add(text) else { return .result(dialog: "Boş bir iş ekleyemem.") }
        let due = item.dueDate.map { dueLabelText(due: $0, now: Date(), calendar: AppModel.shared.calendar).text }
        if let due { return .result(dialog: IntentDialog(LocalizedStringResource("Ekledim: \(item.action), \(due).")) ) }
        return .result(dialog: IntentDialog(LocalizedStringResource("Ekledim: \(item.action).")))
    }
}

struct TodayTasksIntent: AppIntent {
    static let title: LocalizedStringResource = "Bugünkü işlerim"
    static let description = IntentDescription("Gecikmiş ve bugünkü işleri okur.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let model = AppModel.shared
        let now = Date()
        let today = model.store.openItems().filter {
            let b = bucket(for: $0, now: now, calendar: model.calendar)
            return b == .overdue || b == .today
        }
        guard !today.isEmpty else { return .result(dialog: "Bugün için açık işin yok.") }
        let list = today.prefix(5).map { item in item.person.map { "\($0), \(item.action)" } ?? item.action }.joined(separator: "; ")
        return .result(dialog: IntentDialog(LocalizedStringResource("\(today.count) işin var: \(list).")))
    }
}

struct IshlerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddTaskIntent(), phrases: ["\(.applicationName) add task", "Add a task to \(.applicationName)"],
                    shortTitle: "İş ekle", systemImageName: "plus.circle")
        AppShortcut(intent: TodayTasksIntent(), phrases: ["\(.applicationName) what is due today", "\(.applicationName) my tasks today"],
                    shortTitle: "Bugünkü işler", systemImageName: "checklist")
    }
}
