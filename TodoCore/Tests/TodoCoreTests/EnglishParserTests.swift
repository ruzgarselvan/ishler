import Testing
import Foundation
@testable import TodoCore

@MainActor @Suite struct EnglishParserTests {
    let now = date(2026, 10, 24, 15)   // Saturday 15:00
    func parse(_ text: String) -> ParsedEntry {
        EntryParser(knownPeople: [], calendar: istanbul).parse(text, now: now)
    }

    @Test func tomorrowAndToday() {
        let e = parse("Call Deniz tomorrow")
        #expect(e.dueDate == date(2026, 10, 25) && e.person == "Deniz" && e.action == "Call")
        #expect(parse("Email Mert today").dueDate == date(2026, 10, 24))
        #expect(parse("Pay invoice day after tomorrow").dueDate == date(2026, 10, 26))
    }
    @Test func weekdaysWithPrefixWords() {
        let e = parse("Send proposal to Mert by Friday")
        #expect(e.dueDate == date(2026, 10, 30))
        #expect(e.action == "Send proposal")
        #expect(parse("Review on Monday").dueDate == date(2026, 10, 26))
        #expect(parse("Review next monday").dueDate == date(2026, 10, 26))
    }
    @Test func monthNamesBothOrders() {
        #expect(parse("Invoice 24 november Mert").dueDate == date(2026, 11, 24))
        #expect(parse("Invoice November 24th Mert").dueDate == date(2026, 11, 24))
        #expect(parse("Invoice 3rd of March Mert").dueDate == date(2027, 3, 3))
    }
    @Test func relativeAndWeeks() {
        #expect(parse("Follow up in 3 days").dueDate == date(2026, 10, 27))
        #expect(parse("Follow up in two weeks").dueDate == date(2026, 11, 7))
        #expect(parse("Plan next week").dueDate == date(2026, 10, 26))
    }
    @Test func timesWithAmPm() {
        let e = parse("Call Deniz at 5pm")
        #expect(e.dueMinutes == 17 * 60 && e.dueDate == date(2026, 10, 24))
        #expect(e.action == "Call")
        #expect(parse("Call Deniz tomorrow 9:30am").dueMinutes == 9 * 60 + 30)
    }
    @Test func englishRepeats() {
        let e = parse("Plan review every monday")
        #expect(e.repeatRule == "weekly:2" && e.dueDate == date(2026, 10, 26))
        #expect(parse("Back up every day").repeatRule == "daily")
        #expect(parse("Invoice monthly").repeatRule == "monthly")
    }
    @Test func trailingPrepositionIsDropped() {
        let e = parse("Send the proposal to Acme by Friday")
        #expect(e.person == "Acme" && e.action == "Send the proposal")
        #expect(parse("Write to Mert tomorrow").action == "Write")
    }
    @Test func titleBeforeNameStaysWithName() {
        let e = parse("Write to Prof. Tuğba 24 november")
        #expect(e.person == "Prof. Tuğba" && e.action == "Write")
        #expect(parse("Email Dr. Smith tomorrow").person == "Dr. Smith")
    }
}
