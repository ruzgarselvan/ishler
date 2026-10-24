import Testing
import Foundation
@testable import TodoCore

@MainActor @Suite struct CategoryTests {
    let work = TodoCategory(name: "İş", shortcut: "x", colorHex: "#FF9500")
    let home = TodoCategory(name: "Ev", shortcut: "1", colorHex: "#34C759")
    let now = date(2026, 10, 24, 15)

    func parse(_ text: String, options: ShortcutOptions = ShortcutOptions()) -> ParsedEntry {
        EntryParser(knownPeople: [], calendar: istanbul, categories: [work, home], shortcuts: options).parse(text, now: now)
    }

    @Test func trailingLetterShortcut() {
        let e = parse("Mert logo x")
        #expect(e.categoryID == work.id)
        #expect(e.action == "logo")
        #expect(e.person == "Mert")
    }
    @Test func caseInsensitiveAndDigits() {
        #expect(parse("Mert logo X").categoryID == work.id)
        #expect(parse("Mert logo 1").categoryID == home.id)
    }
    @Test func parenthesizedForms() {
        #expect(parse("Mert logo (1)").categoryID == home.id)
        #expect(parse("Mert logo (x)").categoryID == work.id)
        #expect(parse("Mert logo (x)").action == "logo")
    }
    @Test func togglesDisableForms() {
        #expect(parse("Mert logo x", options: .init(letters: false)).categoryID == nil)
        #expect(parse("Mert logo 1", options: .init(digits: false)).categoryID == nil)
        #expect(parse("Mert logo (x)", options: .init(parentheses: false)).categoryID == nil)
        #expect(parse("Mert logo (x)", options: .init(parentheses: false)).action == "logo (x)")
    }
    @Test func onlyTrailingTokenCounts() {
        #expect(parse("x Mert logo").categoryID == nil)
        #expect(parse("x").categoryID == nil)
    }
    @Test func worksWithDate() {
        let e = parse("Cuma'ya Mert teklif x")
        #expect(e.categoryID == work.id)
        #expect(e.dueDate == date(2026, 10, 30))
        #expect(e.action == "teklif")
    }
    @Test func noCategoriesLeavesTextAlone() {
        let e = EntryParser(knownPeople: [], calendar: istanbul).parse("Mert logo x", now: now)
        #expect(e.categoryID == nil)
        #expect(e.action == "logo x")
    }
}
