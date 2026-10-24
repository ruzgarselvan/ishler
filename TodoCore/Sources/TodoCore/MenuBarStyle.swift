import Foundation

/// What the Mac menu bar item shows next to its icon.
public enum MenuBarStyle: String, Codable, CaseIterable, Sendable {
    case count, title, off
}
