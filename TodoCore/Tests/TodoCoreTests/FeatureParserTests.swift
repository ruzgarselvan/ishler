import Testing
import Foundation
@testable import TodoCore

@MainActor @Suite struct FeatureParserTests {
    let now = date(2026, 10, 24, 15)   // Saturday 15:00
    let template = ChecklistTemplate(name: "Çekim sonrası", steps: ["Dosyaları yedekle", "Seçim yap", "Teslim et"])

    func parse(_ text: String) -> ParsedEntry {
        EntryParser(knownPeople: [], calendar: istanbul, templates: [template]).parse(text, now: now)
    }

    @Test func timeLaterTodayStaysToday() {
        let e = parse("Deniz'i ara 17:30")
        #expect(e.dueDate == date(2026, 10, 24))
        #expect(e.dueMinutes == 17 * 60 + 30)
        #expect(e.action == "ara" && e.person == "Deniz")
    }
    @Test func timeAlreadyPassedMovesToTomorrow() {
        let e = parse("Deniz'i ara 14:00")
        #expect(e.dueDate == date(2026, 10, 25))
        #expect(e.dueMinutes == 840)
    }
    @Test func timeWithExplicitDateAndDotSeparator() {
        let e = parse("Cuma 14.30 Mert logo")
        #expect(e.dueDate == date(2026, 10, 30))
        #expect(e.dueMinutes == 870)
        #expect(e.action == "logo")
    }
    @Test func saatNumber() {
        let e = parse("Mert logo saat 9")
        #expect(e.dueMinutes == 540)
        #expect(e.action == "logo")
    }
    @Test func dateNumbersAreNotTimes() {
        #expect(parse("24 kasim Mert ara").dueMinutes == nil)
    }
    @Test func weeklyOnWeekday() {
        let e = parse("her pazartesi Mert haftalık plan")
        #expect(e.repeatRule == "weekly:2")
        #expect(e.dueDate == date(2026, 10, 26))
        #expect(e.action == "haftalık plan")
    }
    @Test func dailyStartsToday() {
        let e = parse("her gün Deniz ara")
        #expect(e.repeatRule == "daily" && e.dueDate == date(2026, 10, 24))
    }
    @Test func monthlyOnDayOfMonth() {
        let e = parse("her ayın 1'i fatura kes")
        #expect(e.repeatRule == "monthly:1")
        #expect(e.dueDate == date(2026, 11, 1))
        #expect(e.action == "fatura kes")
    }
    @Test func plainMonthlyUsesToday() {
        let e = parse("her ay fatura kes")
        #expect(e.repeatRule == "monthly" && e.dueDate == date(2026, 10, 24))
    }
    @Test func templateExpandsToChecklist() {
        let e = parse("çekim sonrası Deniz Cuma")
        #expect(e.action == "Çekim sonrası")
        #expect(e.person == "Deniz")
        #expect(e.dueDate == date(2026, 10, 30))
        #expect(e.checklist == ["Dosyaları yedekle", "Seçim yap", "Teslim et"])
    }
}

@Suite struct RecurrenceTests {
    func next(_ from: Date, _ rule: String) -> Date? { nextOccurrence(after: from, rule: rule, calendar: istanbul) }

    @Test func rules() {
        let d = date(2026, 10, 24)
        #expect(next(d, "daily") == date(2026, 10, 25))
        #expect(next(d, "weekly") == date(2026, 10, 31))
        #expect(next(d, "weekly:2") == date(2026, 10, 26))
        #expect(next(d, "monthly") == date(2026, 11, 24))
        #expect(next(d, "monthly:1") == date(2026, 11, 1))
        #expect(next(date(2026, 10, 31), "monthly:31") == date(2026, 11, 30))
        #expect(next(d, "yearly") == date(2027, 10, 24))
        #expect(next(d, "nonsense") == nil)
    }
}

@MainActor @Suite struct RepeatingStoreTests {
    @Test func doneRepeatingItemSpawnsNextOccurrenceAfterToday() throws {
        let s = try TodoStore(inMemory: true)
        let item = s.add(ParsedEntry(person: "Deniz", action: "ara", dueDate: date(2026, 10, 20), repeatRule: "daily"))!
        s.markDone(item, now: date(2026, 10, 24, 15), calendar: istanbul)
        let open = s.openItems()
        #expect(open.count == 1)
        #expect(open[0].dueDate == date(2026, 10, 25))
        #expect(open[0].person == "Deniz" && open[0].repeatRule == "daily")
        #expect(s.archivedItems().count == 1)
    }
    @Test func checklistRoundTripAndReset() throws {
        let s = try TodoStore(inMemory: true)
        let item = s.add(ParsedEntry(action: "çekim sonrası", dueDate: date(2026, 10, 24), repeatRule: "weekly", checklist: ["a", "b"]))!
        var list = item.checklist
        list[0].done = true
        item.checklist = list
        #expect(item.checklist.map(\.done) == [true, false])
        s.markDone(item, now: date(2026, 10, 24, 15), calendar: istanbul)
        #expect(s.openItems()[0].checklist.map(\.done) == [false, false])
    }
}
