import Foundation
import Observation

@Observable @MainActor
public final class SettingsStore {
    private static let key = "notificationSettings"
    private static let horizonKey = "listHorizon"
    @ObservationIgnored private let defaults: UserDefaults

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
        self.horizon = defaults.string(forKey: Self.horizonKey).flatMap(Horizon.init(rawValue:)) ?? .month
        self.settings = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(NotificationSettings.self, from: $0) } ?? .default
    }
}
