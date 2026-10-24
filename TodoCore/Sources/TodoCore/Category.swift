import Foundation

public struct TodoCategory: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    /// Typed at the end of a note to pick this category: "x", "1", "(x)", "(1)".
    public var shortcut: String
    /// "#RRGGBB"
    public var colorHex: String
    /// Deadline reminders fire only for items of categories with this on. Off by default.
    public var remind: Bool

    public init(id: UUID = UUID(), name: String, shortcut: String, colorHex: String, remind: Bool = false) {
        self.id = id
        self.name = name
        self.shortcut = shortcut
        self.colorHex = colorHex
        self.remind = remind
    }

    /// Categories saved before `remind` existed decode with it off.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        shortcut = try c.decode(String.self, forKey: .shortcut)
        colorHex = try c.decode(String.self, forKey: .colorHex)
        remind = try c.decodeIfPresent(Bool.self, forKey: .remind) ?? false
    }

    public static func defaults() -> [TodoCategory] {
        [
            TodoCategory(name: "İş", shortcut: "x", colorHex: "#FF9500"),
            TodoCategory(name: "Okul", shortcut: "o", colorHex: "#007AFF"),
            TodoCategory(name: "Kişisel", shortcut: "k", colorHex: "#34C759"),
        ]
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
