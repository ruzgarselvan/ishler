import Foundation
import Observation
import TodoCore

@Observable @MainActor
final class AppModel {
    let store: TodoStore
    let settingsStore: SettingsStore
    let calendar: Calendar
    @ObservationIgnored private let scheduler = NotificationScheduler()

    init(store: TodoStore, settingsStore: SettingsStore = SettingsStore()) {
        self.store = store
        self.settingsStore = settingsStore
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "tr_TR")
        c.firstWeekday = 2
        self.calendar = c
    }

    var parser: EntryParser { EntryParser(knownPeople: store.knownPeople(), calendar: calendar) }

    func start() async {
        _ = await SystemNotificationCenter.requestAuthorization()
        await reschedule()
    }

    func add(_ text: String) {
        store.add(parser.parse(text, now: Date()))
        Task { await reschedule() }
    }

    func markDone(_ item: TodoItem) {
        store.markDone(item, now: Date())
        Task { await reschedule() }
    }

    func reopen(_ item: TodoItem) {
        store.reopen(item)
        Task { await reschedule() }
    }

    func reschedule() async {
        await scheduler.reschedule(items: store.openItems(), settings: settingsStore.settings, now: Date(), calendar: calendar)
    }
}
