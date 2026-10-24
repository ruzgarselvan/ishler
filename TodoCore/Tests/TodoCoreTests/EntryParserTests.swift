import Testing
import Foundation
@testable import TodoCore

@Suite struct EntryParserTests {
    let saturday = date(2026, 10, 24, 15)
    let friday = date(2026, 10, 30, 15)

    func parse(_ text: String, now: Date? = nil, known: [String] = []) -> ParsedEntry {
        EntryParser(knownPeople: known, calendar: istanbul).parse(text, now: now ?? saturday)
    }

    @Test func fullSentence() {
        let e = parse("Cuma'ya kadar X müşterisine teklif at")
        #expect(e.person == "X")
        #expect(e.action == "teklif at")
        #expect(e.dueDate == date(2026, 10, 30))
        #expect(e.dateText == "Cuma'ya kadar")
    }
    @Test func noDate() {
        let e = parse("Deniz'i ara")
        #expect(e.person == "Deniz")
        #expect(e.action == "ara")
        #expect(e.dueDate == nil)
    }
    @Test func noPerson() {
        let e = parse("yarın faturayı gönder")
        #expect(e.person == nil)
        #expect(e.action == "faturayı gönder")
        #expect(e.dueDate == date(2026, 10, 25))
    }
    @Test func fridayOnFriday() {
        let e = parse("Cuma'ya X'e teklif at", now: friday)
        #expect(e.dueDate == date(2026, 10, 30))
    }
    @Test func caseInsensitive() {
        let e = parse("CUMA günü Ayşe fatura")
        #expect(e.dueDate == date(2026, 10, 30))
        #expect(e.person == "Ayşe")
        #expect(e.action == "fatura")
    }
    @Test func knownPersonWins() {
        let e = parse("mert revizyon", known: ["Mert"])
        #expect(e.person == "Mert")
        #expect(e.action == "revizyon")
    }
    @Test func explicitDate() {
        let e = parse("15 Kasım'a kadar Mert logo")
        #expect(e.dueDate == date(2026, 11, 15))
        #expect(e.person == "Mert")
        #expect(e.action == "logo")
    }
    @Test func relativeWeek() {
        let e = parse("gelecek hafta Deniz'i ara")
        #expect(e.dueDate == date(2026, 10, 26))
        #expect(e.person == "Deniz")
    }
    @Test func daysLater() {
        #expect(parse("3 gün sonra Mert ara").dueDate == date(2026, 10, 27))
    }
    @Test func emptyInput() {
        #expect(parse("   ").action == "")
    }
    @Test func numberWordDaysLater() {
        let e = parse("üç gün sonra ahmete git")
        #expect(e.dueDate == date(2026, 10, 27))
        #expect(e.action == "ahmete git")
        #expect(e.dateText == "üç gün sonra")
    }
    @Test func weeksAndMonthsLater() {
        #expect(parse("2 hafta sonra Mert ara").dueDate == date(2026, 11, 7))
        #expect(parse("bir hafta sonra Mert ara").dueDate == date(2026, 10, 31))
        #expect(parse("iki ay sonra Mert ara").dueDate == date(2026, 12, 24))
    }
    @Test func worksWithoutTurkishCharacters() {
        let e = parse("tugba hocayi ara 24 kasim")
        #expect(e.dueDate == date(2026, 11, 24))
        #expect(e.action == "tugba hocayi ara")
        #expect(parse("yarin Mert ara").dueDate == date(2026, 10, 25))
        #expect(parse("uc gun sonra Mert ara").dueDate == date(2026, 10, 27))
        #expect(parse("Mert musterisine sali gunu teklif").dueDate == date(2026, 10, 27))
        #expect(parse("Cumartesi'ye Ayse fatura").person == "Ayse")
    }
    @Test func knownPersonMatchesWithoutDiacritics() {
        let e = parse("ayse fatura", known: ["Ayşe"])
        #expect(e.person == "Ayşe")
    }
}
