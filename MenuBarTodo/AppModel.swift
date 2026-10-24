import Foundation
import Observation
import ServiceManagement
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

    /// Open items that are overdue or due today (undated ones count as today).
    private(set) var badgeCount = 0

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            if newValue { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
        }
    }

    func refreshBadge() {
        let now = Date()
        badgeCount = store.openItems().filter {
            let b = bucket(for: $0, now: now, calendar: calendar)
            return b == .overdue || b == .today
        }.count
    }

    var parser: EntryParser { EntryParser(knownPeople: store.knownPeople(), calendar: calendar) }

    func start() async {
        _ = await SystemNotificationCenter.requestAuthorization()
        await reschedule()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(15 * 60))
            await reschedule()
        }
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
        refreshBadge()
        await scheduler.reschedule(items: store.openItems(), settings: settingsStore.settings, now: Date(), calendar: calendar)
    }
}
