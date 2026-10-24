import CloudKit
import CoreSpotlight
import Foundation
import Observation
import SwiftUI
import UserNotifications
import WidgetKit
#if os(macOS)
import AppKit
import ServiceManagement
#endif
import TodoCore

@Observable @MainActor
final class AppModel {
    /// One model per process, so App Intents (Siri, Shortcuts) write to the same store as the UI.
    static let shared = AppModel(store: try! TodoStore())

    let store: TodoStore
    let settingsStore: SettingsStore
    let calendar: Calendar
    @ObservationIgnored private let scheduler = NotificationScheduler()
    @ObservationIgnored private let calendarSync = CalendarSync()
    @ObservationIgnored private let notificationHandler = NotificationHandler()

    /// Open items that are overdue or due today (undated ones count as today).
    private(set) var badgeCount = 0
    /// The next item to do, short enough for the menu bar.
    private(set) var nextItemText = ""

    init(store: TodoStore, settingsStore: SettingsStore = SettingsStore()) {
        self.store = store
        self.settingsStore = settingsStore
        var c = Calendar(identifier: .gregorian)
        c.locale = appLocale
        self.calendar = c
        notificationHandler.model = self
    }

    // MARK: Appearance and platform

    #if os(macOS)
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            if newValue { try? SMAppService.mainApp.register() } else { try? SMAppService.mainApp.unregister() }
        }
    }

    /// nil follows the system; the menu bar panel has no scene to hang preferredColorScheme on.
    func applyAppearance() {
        NSApp.appearance = switch settingsStore.appearance {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
    #endif

    var colorScheme: ColorScheme? {
        switch settingsStore.appearance {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    // MARK: Activity

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

    // MARK: Parsing and display

    var parser: EntryParser {
        EntryParser(knownPeople: store.knownPeople(), calendar: calendar, categories: settingsStore.categories,
                    shortcuts: settingsStore.shortcuts, templates: settingsStore.templates)
    }

    func color(for item: TodoItem) -> Color? {
        settingsStore.category(item.categoryID).map { Color(hex: $0.colorHex) }
    }

    func refreshBadge() {
        let now = Date()
        let open = store.openItems()
        badgeCount = open.filter {
            let b = bucket(for: $0, now: now, calendar: calendar)
            return b == .overdue || b == .today
        }.count
        if let next = sortedOpenItems(open, now: now, calendar: calendar).first?.1.first {
            let text = next.person.map { "\($0) · \(next.action)" } ?? next.action
            nextItemText = text.count > 24 ? String(text.prefix(23)) + "…" : text
        } else {
            nextItemText = ""
        }
    }

    /// "1.0 (4)" from the app bundle.
    static var versionText: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
    }

    // MARK: iCloud status

    /// Short human-readable sync state shown at the bottom of Settings.
    private(set) var iCloudStatus = ""

    func refreshICloudStatus() async {
        guard store.usesICloud else {
            iCloudStatus = String(localized: "iCloud kapalı: işler sadece bu cihazda duruyor")
            return
        }
        let status = (try? await CKContainer(identifier: TodoStore.cloudContainerID).accountStatus()) ?? .couldNotDetermine
        switch status {
        case .available: iCloudStatus = String(localized: "iCloud açık: işler cihazların arasında eşitleniyor")
        case .noAccount: iCloudStatus = String(localized: "iCloud hesabı yok: Ayarlar'dan iCloud'a giriş yap")
        case .restricted: iCloudStatus = String(localized: "iCloud kısıtlı: bu cihazda kullanılamıyor")
        default: iCloudStatus = String(localized: "iCloud durumu bilinmiyor")
        }
        #if DEBUG
        FileHandle.standardError.write(Data("ishler: iCloud status = \(iCloudStatus)\n".utf8))
        #endif
    }

    // MARK: Lifecycle

    func start() async {
        UNUserNotificationCenter.current().delegate = notificationHandler
        NotificationActions.register()
        // Asking can wait on the user, so it must not hold up the rest of start-up; notifications re-plan once answered.
        Task { _ = await SystemNotificationCenter.requestAuthorization(); await reschedule() }
        UserDefaults.standard.set(Date(), forKey: Self.activityKey)
        #if os(macOS)
        applyAppearance()
        #endif
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-initCloudSchema") {
            // Background-only menu bar apps get their CloudKit requests deferred ("discretionary"); act like a normal app for this run.
            #if os(macOS)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            try? await Task.sleep(for: .seconds(1))
            #endif
            do { try await Task.detached(priority: .userInitiated) { try TodoStore.initializeCloudKitSchema() }.value; FileHandle.standardError.write(Data("ishler: CloudKit schema initialized\n".utf8)) }
            catch { FileHandle.standardError.write(Data("ishler: schema init failed: \(error)\n".utf8)) }
        }
        if ProcessInfo.processInfo.arguments.contains("-seedDemo"), store.allItems().isEmpty {
            for text in ["Cuma'ya kadar X müşterisine teklif at x", "Deniz'i ara 17:30", "her pazartesi Mert haftalık plan",
                         "çekim sonrası Deniz Cuma", "tuğba hocaya yaz 24 kasim", "Call Mert tomorrow 9:30am", "Pay invoice by Friday 1",
                         "Ayşe'ye mail at (o)"] { add(text) }
            store.add(ParsedEntry(person: "Ayşe", action: "faturayı gönder", dueDate: calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: Date()))))
            if !settingsStore.categories.isEmpty { settingsStore.categories[0].remind = true }
        }
        // Debug aid: `-seedCloudKit` adds one item so CloudKit creates its record type in the Development schema.
        if ProcessInfo.processInfo.arguments.contains("-seedCloudKit"), !store.allItems().contains(where: { $0.action == "iCloud test" }) {
            add("iCloud test")
        }
        #endif
        await refreshICloudStatus()
        await reschedule()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(15 * 60))
            await reschedule()
        }
    }

    // MARK: Changes

    @discardableResult
    func add(_ text: String) -> TodoItem? {
        let item = store.add(parser.parse(text, now: Date()))
        touch()
        return item
    }

    func markDone(_ item: TodoItem) {
        store.markDone(item, now: Date(), calendar: calendar)
        touch()
    }

    func update(_ item: TodoItem, person: String?, action: String, dueDate: Date?, dueMinutes: Int?, categoryID: UUID?) -> Bool {
        let ok = store.update(item, person: person, action: action, dueDate: dueDate, dueMinutes: dueMinutes, categoryID: categoryID)
        if ok { touch() }
        return ok
    }

    func delete(_ item: TodoItem) {
        let eventID = item.eventID
        store.delete(item)
        Task { await calendarSync.remove(eventID: eventID) }
        touch()
    }

    func reopen(_ item: TodoItem) {
        store.reopen(item)
        touch()
    }

    /// Persists edits made directly on an item (for example ticking a checklist step).
    func save() {
        store.save()
        Task { await reschedule() }
    }

    // MARK: Notification buttons

    func handle(action: String, itemID: UUID, title: String, body: String) {
        switch action {
        case NotificationActions.done:
            if let item = store.item(id: itemID) { markDone(item) }
        case NotificationActions.snoozeHour:
            snooze(title: title, body: body, itemID: itemID, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false))
        case NotificationActions.snoozeTomorrow:
            let morning = settingsStore.settings.morningTime
            var parts = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: 1, to: Date())!)
            parts.hour = morning.hour
            parts.minute = morning.minute
            snooze(title: title, body: body, itemID: itemID, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
        default:
            touch()
        }
    }

    private func snooze(title: String, body: String, itemID: UUID, trigger: UNNotificationTrigger) {
        let copy = UNMutableNotificationContent()
        copy.title = title
        copy.body = body
        copy.sound = .default
        copy.categoryIdentifier = NotificationActions.category
        copy.userInfo = [NotificationActions.itemKey: itemID.uuidString]
        let request = UNNotificationRequest(identifier: "snooze-\(itemID.uuidString)-\(Int(Date().timeIntervalSince1970))",
                                            content: copy, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Writes all items to a temporary CSV file and returns its URL, for the share sheet.
    func makeExport() -> URL? {
        let csv = csvExport(items: store.allItems(), categories: settingsStore.categories, calendar: calendar)
        let url = FileManager.default.temporaryDirectory.appending(path: "ishler-tasks.csv")
        return (try? csv.write(to: url, atomically: true, encoding: .utf8)) != nil ? url : nil
    }

    // MARK: Rescheduling and mirrors

    func reschedule() async {
        store.ensureRoutines(settingsStore.templates, now: Date(), calendar: calendar)
        refreshBadge()
        await scheduler.reschedule(items: store.openItems(), settings: settingsStore.settings, now: Date(), calendar: calendar,
                                  reminderCategories: settingsStore.reminderCategoryIDs, lastActivity: lastActivity)
        if settingsStore.writeToCalendar {
            await calendarSync.sync(items: store.allItems(), calendar: calendar)
            store.save()
        }
        indexSpotlight()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func indexSpotlight() {
        let now = Date()
        let items = store.openItems().map { item -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(contentType: .item)
            attributes.title = item.person.map { "\($0) · \(item.action)" } ?? item.action
            attributes.contentDescription = item.dueDate.map { dueLabelText(due: $0, now: now, calendar: calendar).text } ?? String(localized: "Bekliyor")
            return CSSearchableItem(uniqueIdentifier: item.id.uuidString, domainIdentifier: "ishler", attributeSet: attributes)
        }
        let index = CSSearchableIndex.default()
        index.deleteAllSearchableItems { _ in index.indexSearchableItems(items) }
    }
}
