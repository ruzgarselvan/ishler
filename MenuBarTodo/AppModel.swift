import Foundation
import Observation
import TodoCore

@Observable @MainActor
final class AppModel {
    let store: TodoStore
    let calendar: Calendar

    init(store: TodoStore) {
        self.store = store
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "tr_TR")
        c.firstWeekday = 2
        self.calendar = c
    }

    var parser: EntryParser { EntryParser(knownPeople: store.knownPeople(), calendar: calendar) }

    func add(_ text: String) {
        let entry = parser.parse(text, now: Date())
        store.add(entry)
    }

    func markDone(_ item: TodoItem) { store.markDone(item, now: Date()) }
    func reopen(_ item: TodoItem) { store.reopen(item) }
}
