import Testing
import Foundation
@testable import TodoCore

@MainActor @Suite struct TodoStoreTests {
    func store() throws -> TodoStore { try TodoStore(inMemory: true) }

    @Test func addStoresItem() throws {
        let s = try store()
        let item = s.add(ParsedEntry(person: "X", action: "teklif at", dueDate: date(2026, 10, 30)))
        #expect(item != nil)
        #expect(s.openItems().count == 1)
        #expect(s.openItems()[0].person == "X")
    }
    @Test func addRejectsEmptyAction() throws {
        let s = try store()
        #expect(s.add(ParsedEntry(action: "  ")) == nil)
        #expect(s.openItems().isEmpty)
    }
    @Test func markDoneMovesToArchive() throws {
        let s = try store()
        let item = s.add(ParsedEntry(action: "ara"))!
        s.markDone(item, now: date(2026, 10, 24))
        #expect(s.openItems().isEmpty)
        #expect(s.archivedItems().count == 1)
    }
    @Test func reopenReturnsToOpen() throws {
        let s = try store()
        let item = s.add(ParsedEntry(action: "ara"))!
        s.markDone(item, now: date(2026, 10, 24))
        s.reopen(item)
        #expect(s.openItems().count == 1)
        #expect(s.archivedItems().isEmpty)
    }
    @Test func archiveNewestFirst() throws {
        let s = try store()
        let a = s.add(ParsedEntry(action: "a"))!, b = s.add(ParsedEntry(action: "b"))!
        s.markDone(a, now: date(2026, 10, 20)); s.markDone(b, now: date(2026, 10, 22))
        #expect(s.archivedItems().map(\.action) == ["b", "a"])
    }
    @Test func knownPeopleUniqueAndMostUsedFirst() throws {
        let s = try store()
        _ = s.add(ParsedEntry(person: "Deniz", action: "1"))
        _ = s.add(ParsedEntry(person: "Mert", action: "2"))
        _ = s.add(ParsedEntry(person: "Mert", action: "3"))
        _ = s.add(ParsedEntry(action: "4"))
        #expect(s.knownPeople() == ["Mert", "Deniz"])
    }
    @Test func deleteRemoves() throws {
        let s = try store()
        let item = s.add(ParsedEntry(action: "ara"))!
        s.delete(item)
        #expect(s.openItems().isEmpty && s.archivedItems().isEmpty)
    }
}
