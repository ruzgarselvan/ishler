import Testing
import Foundation
@testable import TodoCore

let now = date(2026, 10, 24, 15)

func item(_ action: String = "iş", person: String? = nil, due: Date?, done: Date? = nil) -> TodoItem {
    let i = TodoItem(person: person, action: action, dueDate: due)
    i.doneAt = done
    return i
}

@Suite struct BucketTests {
    @Test func undatedItemIsToday() {
        #expect(bucket(for: item(due: nil), now: now, calendar: istanbul) == .today)
    }
    @Test func yesterdayIsOverdue() {
        #expect(bucket(for: item(due: date(2026, 10, 23)), now: now, calendar: istanbul) == .overdue)
    }
    @Test func todayLateEveningIsToday() {
        #expect(bucket(for: item(due: date(2026, 10, 24, 23, 59)), now: now, calendar: istanbul) == .today)
    }
    @Test func nextFridayIsThisWeek() {
        #expect(bucket(for: item(due: date(2026, 10, 30)), now: now, calendar: istanbul) == .thisWeek)
    }
    @Test func eightDaysAheadIsLater() {
        #expect(bucket(for: item(due: date(2026, 11, 1)), now: now, calendar: istanbul) == .later)
    }
    @Test func doneItemsExcluded() {
        let groups = sortedOpenItems([item(due: nil, done: now)], now: now, calendar: istanbul)
        #expect(groups.isEmpty)
    }
    @Test func undatedSortsAfterDatedInToday() {
        let undated = item("ara", due: nil)
        let dated = item("fatura", due: date(2026, 10, 24, 9))
        let groups = sortedOpenItems([undated, dated], now: now, calendar: istanbul)
        #expect(groups.count == 1)
        #expect(groups[0].0 == .today)
        #expect(groups[0].1.map(\.action) == ["fatura", "ara"])
    }
}

@Suite struct DueLabelTests {
    func label(_ due: Date) -> String { dueLabelText(due: due, now: now, calendar: istanbul).text }

    @Test func relativeThenDate() {
        #expect(label(date(2026, 10, 24)) == "Bugün")
        #expect(label(date(2026, 10, 25)) == "Yarın")
        #expect(label(date(2026, 11, 23)) == "23 Kasım")
        #expect(label(date(2026, 10, 27)) == "27 Ekim")
    }
    @Test func overdueWording() {
        #expect(label(date(2026, 10, 23)) == "Dün")
        #expect(label(date(2026, 10, 21)) == "3 gün önce")
        #expect(dueLabelText(due: date(2026, 10, 21), now: now, calendar: istanbul).isOverdue)
    }
}
