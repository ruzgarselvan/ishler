import Foundation

public struct TodoCategory: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    /// Typed at the end of a note to pick this category: "x", "1", "(x)", "(1)".
    public var shortcut: String
    /// "#RRGGBB"
    public var colorHex: String

    public init(id: UUID = UUID(), name: String, shortcut: String, colorHex: String) {
        self.id = id
        self.name = name
        self.shortcut = shortcut
        self.colorHex = colorHex
    }
}

/// Which spellings of a category shortcut are accepted at the end of a note.
public struct ShortcutOptions: Codable, Equatable, Sendable {
    public var letters: Bool
    public var digits: Bool
    public var parentheses: Bool

    public init(letters: Bool = true, digits: Bool = true, parentheses: Bool = true) {
        self.letters = letters
        self.digits = digits
        self.parentheses = parentheses
    }
}
