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
        context.insert(item)
        try? context.save()
        return item
    }

    public func markDone(_ item: TodoItem, now: Date) {
        item.doneAt = now
        try? context.save()
    }

    public func reopen(_ item: TodoItem) {
        item.doneAt = nil
        try? context.save()
    }

    public func delete(_ item: TodoItem) {
        context.delete(item)
        try? context.save()
    }

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
