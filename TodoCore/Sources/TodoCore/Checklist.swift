import Foundation

public struct ChecklistEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var done: Bool

    public init(id: UUID = UUID(), title: String, done: Bool = false) {
        self.id = id
        self.title = title
        self.done = done
    }
}

/// A named set of steps; typing its name at the start of a note adds the steps as a checklist.
public struct ChecklistTemplate: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var steps: [String]

    public init(id: UUID = UUID(), name: String, steps: [String]) {
        self.id = id
        self.name = name
        self.steps = steps
    }
}

extension TodoItem {
    public var checklist: [ChecklistEntry] {
        get { checklistData.flatMap { try? JSONDecoder().decode([ChecklistEntry].self, from: $0) } ?? [] }
        set { checklistData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue) }
    }
}
