import Foundation
import SwiftData

@MainActor
public final class TodoStore {
    public let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    public init(inMemory: Bool = false) throws {
        let schema = Schema([TodoItem.self])
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(isStoredInMemoryOnly: true)
        } else {
            let dir = URL.applicationSupportDirectory.appending(path: "MenuBarTodo", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            config = ModelConfiguration(schema: schema, url: dir.appending(path: "todo.store"))
        }
        container = try ModelContainer(for: schema, configurations: config)
    }

    @discardableResult
    public func add(_ entry: ParsedEntry) -> TodoItem? {
        let action = entry.action.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !action.isEmpty else { return nil }
        let item = TodoItem(person: entry.person, action: action, dueDate: entry.dueDate)
        item.categoryID = entry.categoryID
        item.dueMinutes = entry.dueMinutes
        item.repeatRule = entry.repeatRule
        item.checklist = entry.checklist.map { ChecklistEntry(title: $0) }
        context.insert(item)
        try? context.save()
        return item
    }

    /// Completing a repeating item also creates its next occurrence (the first one after today).
    public func markDone(_ item: TodoItem, now: Date, calendar: Calendar = .current) {
        item.doneAt = now
        if let rule = item.repeatRule, let due = item.dueDate {
            let today = calendar.startOfDay(for: now)
            var next = nextOccurrence(after: due, rule: rule, calendar: calendar)
            while let n = next, n <= today { next = nextOccurrence(after: n, rule: rule, calendar: calendar) }
            if let next {
                let copy = TodoItem(person: item.person, action: item.action, dueDate: next)
                copy.categoryID = item.categoryID
                copy.dueMinutes = item.dueMinutes
                copy.repeatRule = rule
                copy.checklist = item.checklist.map { ChecklistEntry(title: $0.title) }
                context.insert(copy)
            }
        }
        try? context.save()
    }

    public func reopen(_ item: TodoItem) {
        item.doneAt = nil
        try? context.save()
    }

    /// Returns false (and changes nothing) when `action` is blank.
    @discardableResult
    public func update(_ item: TodoItem, person: String?, action: String, dueDate: Date?, categoryID: UUID?) -> Bool {
        let action = action.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !action.isEmpty else { return false }
        let person = person?.trimmingCharacters(in: .whitespacesAndNewlines)
        item.person = (person?.isEmpty ?? true) ? nil : person
        item.action = action
        item.dueDate = dueDate
        item.categoryID = categoryID
        try? context.save()
        return true
    }

    public func delete(_ item: TodoItem) {
        context.delete(item)
        try? context.save()
    }

    public func allItems() -> [TodoItem] { all() }

    public func save() { try? context.save() }

    public func item(id: UUID) -> TodoItem? { all().first { $0.id == id } }

    public func openItems() -> [TodoItem] {
        all().filter { !$0.isDone }
    }

    public func archivedItems() -> [TodoItem] {
        all().filter(\.isDone).sorted { ($0.doneAt ?? .distantPast) > ($1.doneAt ?? .distantPast) }
    }

    public func knownPeople() -> [String] {
        let counts = all().compactMap(\.person).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        return counts.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.map(\.key)
    }

    private func all() -> [TodoItem] {
        (try? context.fetch(FetchDescriptor<TodoItem>())) ?? []
    }
}
