import Foundation

/// Light/dark choice made inside the app; `.system` follows the device setting.
public enum Appearance: String, Codable, CaseIterable, Sendable {
    case system, light, dark
}
