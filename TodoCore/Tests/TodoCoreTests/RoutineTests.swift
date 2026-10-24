import Testing
import Foundation
@testable import TodoCore

@MainActor @Suite struct RoutineTests {
    let now = date(2026, 10, 24, 15)   // Saturday
    let invoice = ChecklistTemplate(name: "Fatura kes", steps: ["Taslak", "Gönder"], schedule: "monthly:15")

    @Test func scheduledRoutineCreatesOneOpenItemWithItsSchedule() throws {
        let s = try TodoStore(inMemory: true)
        s.ensureRoutines([invoice], now: now, calendar: istanbul)
        s.ensureRoutines([invoice], now: now, calendar: istanbul)
        let open = s.openItems()
        #expect(open.count == 1)
        #expect(open[0].action == "Fatura kes")
        #expect(open[0].dueDate == date(2026, 11, 15))
        #expect(open[0].repeatRule == "monthly:15")
        #expect(open[0].routineID == invoice.id)
        #expect(open[0].checklist.map(\.title) == ["Taslak", "Gönder"])
    }
    @Test func dueTodayCountsWhenTodayIsTheDay() throws {
        let s = try TodoStore(inMemory: true)
        s.ensureRoutines([invoice], now: date(2026, 11, 15, 9), calendar: istanbul)
        #expect(s.openItems()[0].dueDate == date(2026, 11, 15))
    }
    @Test func finishingItSpawnsNextMonthWithoutDuplicates() throws {
        let s = try TodoStore(inMemory: true)
        s.ensureRoutines([invoice], now: now, calendar: istanbul)
        s.markDone(s.openItems()[0], now: date(2026, 11, 15, 10), calendar: istanbul)
        s.ensureRoutines([invoice], now: date(2026, 11, 15, 11), calendar: istanbul)
        let open = s.openItems()
        #expect(open.count == 1)
        #expect(open[0].dueDate == date(2026, 12, 15) && open[0].routineID == invoice.id)
    }
    @Test func unscheduledTemplatesAreNotRoutines() throws {
        let s = try TodoStore(inMemory: true)
        s.ensureRoutines([ChecklistTemplate(name: "Çekim sonrası", steps: ["a"])], now: now, calendar: istanbul)
        #expect(s.openItems().isEmpty)
    }
    @Test func firstOccurrenceIncludesToday() {
        #expect(firstOccurrence(of: "weekly:7", from: date(2026, 10, 24), calendar: istanbul) == date(2026, 10, 24))
        #expect(firstOccurrence(of: "monthly:24", from: date(2026, 10, 24), calendar: istanbul) == date(2026, 10, 24))
        #expect(firstOccurrence(of: "daily", from: date(2026, 10, 24), calendar: istanbul) == date(2026, 10, 24))
    }
}
