import Foundation

/// What the Mac menu bar item shows next to its icon.
public enum MenuBarStyle: String, Codable, CaseIterable, Sendable {
    case count, title, off
}

/// Where the Mac app lives: only in the menu bar, only in the Dock as a normal app, or both.
public enum AppMode: String, Codable, CaseIterable, Sendable {
    case menuBar, dock, both

    public var showsMenuBarIcon: Bool { self != .dock }
    public var showsDockIcon: Bool { self != .menuBar }
}
