import Foundation
import Observation

@Observable @MainActor
public final class SettingsStore {
    private static let key = "notificationSettings"
    private static let horizonKey = "listHorizon"
    private static let badgeKey = "showBadge"
    private static let categoriesKey = "categories"
    private static let shortcutsKey = "shortcutOptions"
    @ObservationIgnored private let defaults: UserDefaults

    public var categories: [TodoCategory] {
        didSet { if let data = try? JSONEncoder().encode(categories) { defaults.set(data, forKey: Self.categoriesKey) } }
    }
    public var shortcuts: ShortcutOptions {
        didSet { if let data = try? JSONEncoder().encode(shortcuts) { defaults.set(data, forKey: Self.shortcutsKey) } }
    }

    public var reminderCategoryIDs: Set<UUID> { Set(categories.filter(\.remind).map(\.id)) }

    public func category(_ id: UUID?) -> TodoCategory? {
        guard let id else { return nil }
        return categories.first { $0.id == id }
    }

    public var showBadge: Bool {
        didSet { defaults.set(showBadge, forKey: Self.badgeKey) }
    }

    public var horizon: Horizon {
        didSet { defaults.set(horizon.rawValue, forKey: Self.horizonKey) }
    }

    public var settings: NotificationSettings {
        didSet {
            if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: Self.key) }
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.categoriesKey), let saved = try? JSONDecoder().decode([TodoCategory].self, from: data) {
            self.categories = saved
        } else {
            // First launch: seed the defaults and save them now, so their ids stay stable.
            let seeded = TodoCategory.defaults()
            self.categories = seeded
            if let data = try? JSONEncoder().encode(seeded) { defaults.set(data, forKey: Self.categoriesKey) }
        }
        self.shortcuts = defaults.data(forKey: Self.shortcutsKey).flatMap { try? JSONDecoder().decode(ShortcutOptions.self, from: $0) } ?? ShortcutOptions()
        self.showBadge = defaults.object(forKey: Self.badgeKey) as? Bool ?? true
        self.horizon = defaults.string(forKey: Self.horizonKey).flatMap(Horizon.init(rawValue:)) ?? .month
        self.settings = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(NotificationSettings.self, from: $0) } ?? .default
    }
}
