import Foundation
import Observation

@Observable @MainActor
public final class SettingsStore {
    private enum Key {
        static let notifications = "notificationSettings"
        static let horizon = "listHorizon"
        static let badge = "showBadge"
        static let menuBar = "menuBarStyle"
        static let appearance = "appearance"
        static let categories = "categories"
        static let shortcuts = "shortcutOptions"
        static let templates = "templates"
        static let calendarWrite = "writeToCalendar"
        static let quickAdd = "quickAddHotkey"
    }
    @ObservationIgnored private let defaults: UserDefaults

    public var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) } }
    public var horizon: Horizon { didSet { defaults.set(horizon.rawValue, forKey: Key.horizon) } }
    public var menuBarStyle: MenuBarStyle { didSet { defaults.set(menuBarStyle.rawValue, forKey: Key.menuBar) } }
    /// Mirror dated items into Apple Calendar.
    public var writeToCalendar: Bool { didSet { defaults.set(writeToCalendar, forKey: Key.calendarWrite) } }
    /// Mac only: global shortcut that opens the quick-add window.
    public var quickAddHotkey: Bool { didSet { defaults.set(quickAddHotkey, forKey: Key.quickAdd) } }

    public var categories: [TodoCategory] { didSet { save(categories, Key.categories) } }
    public var shortcuts: ShortcutOptions { didSet { save(shortcuts, Key.shortcuts) } }
    public var templates: [ChecklistTemplate] { didSet { save(templates, Key.templates) } }
    public var settings: NotificationSettings { didSet { save(settings, Key.notifications) } }

    public var reminderCategoryIDs: Set<UUID> { Set(categories.filter(\.remind).map(\.id)) }

    public func category(_ id: UUID?) -> TodoCategory? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
            defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
        }
        // First launch: seed the defaults and save them right away so their ids stay stable.
        func seeded<T: Codable>(_ key: String, _ value: [T]) -> [T] {
            if let saved = load([T].self, key) { return saved }
            if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
            return value
        }
        self.categories = seeded(Key.categories, TodoCategory.defaults())
        self.templates = seeded(Key.templates, [ChecklistTemplate.example])
        self.shortcuts = load(ShortcutOptions.self, Key.shortcuts) ?? ShortcutOptions()
        self.settings = load(NotificationSettings.self, Key.notifications) ?? .default
        self.appearance = defaults.string(forKey: Key.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        self.horizon = defaults.string(forKey: Key.horizon).flatMap(Horizon.init(rawValue:)) ?? .month
        // The old on/off badge toggle maps to .count / .off.
        let legacyBadge = defaults.object(forKey: Key.badge) as? Bool ?? true
        self.menuBarStyle = defaults.string(forKey: Key.menuBar).flatMap(MenuBarStyle.init(rawValue:)) ?? (legacyBadge ? .count : .off)
        self.writeToCalendar = defaults.object(forKey: Key.calendarWrite) as? Bool ?? true
        self.quickAddHotkey = defaults.object(forKey: Key.quickAdd) as? Bool ?? true
    }

    private func save<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
}
