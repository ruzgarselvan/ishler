import Foundation
import Observation

@Observable @MainActor
public final class SettingsStore {
    private static let key = "notificationSettings"
    @ObservationIgnored private let defaults: UserDefaults

    public var settings: NotificationSettings {
        didSet {
            if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: Self.key) }
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.settings = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(NotificationSettings.self, from: $0) } ?? .default
    }
}
