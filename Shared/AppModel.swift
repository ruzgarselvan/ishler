import Foundation
import Observation
import SwiftUI
#if os(macOS)
import ServiceManagement
#endif
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

    #if os(macOS)
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            if newValue { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
        }
    }
    #endif

    private static let activityKey = "lastActivity"

    /// When the user last opened the app or changed something; drives the "Seni bekleyen işler var!" nudge.
    var lastActivity: Date {
        UserDefaults.standard.object(forKey: Self.activityKey) as? Date ?? Date()
    }

    /// Records activity now and re-plans notifications (the nudge moves forward).
    func touch() {
        UserDefaults.standard.set(Date(), forKey: Self.activityKey)
        Task { await reschedule() }
    }

    func refreshBadge() {
        let now = Date()
        badgeCount = store.openItems().filter {
            let b = bucket(for: $0, now: now, calendar: calendar)
            return b == .overdue || b == .today
        }.count
    }

    var parser: EntryParser {
        EntryParser(knownPeople: store.knownPeople(), calendar: calendar,
                    categories: settingsStore.categories, shortcuts: settingsStore.shortcuts)
    }

    func color(for item: TodoItem) -> Color? {
        settingsStore.category(item.categoryID).map { Color(hex: $0.colorHex) }
    }

    func start() async {
        _ = await SystemNotificationCenter.requestAuthorization()
        UserDefaults.standard.set(Date(), forKey: Self.activityKey)
        await reschedule()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(15 * 60))
            await reschedule()
        }
    }

    func add(_ text: String) {
        store.add(parser.parse(text, now: Date()))
        touch()
    }

    func markDone(_ item: TodoItem) {
        store.markDone(item, now: Date())
        touch()
    }

    func update(_ item: TodoItem, person: String?, action: String, dueDate: Date?, categoryID: UUID?) -> Bool {
        let ok = store.update(item, person: person, action: action, dueDate: dueDate, categoryID: categoryID)
        if ok { touch() }
        return ok
    }

    func delete(_ item: TodoItem) {
        store.delete(item)
        touch()
    }

    func reopen(_ item: TodoItem) {
        store.reopen(item)
        touch()
    }

    func reschedule() async {
        refreshBadge()
        await scheduler.reschedule(items: store.openItems(), settings: settingsStore.settings, now: Date(), calendar: calendar,
                                  reminderCategories: settingsStore.reminderCategoryIDs, lastActivity: lastActivity)
    }
}
