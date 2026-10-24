import Testing
import Foundation
@testable import TodoCore

@Suite struct NotificationPlannerTests {
    let settings = NotificationSettings.default
    let morning = date(2026, 10, 24, 9)
    let work = UUID()

    func plan(_ items: [TodoItem], now: Date? = nil, reminders: Set<UUID>? = nil) -> [PlannedNotification] {
        planNotifications(items: items, settings: settings, now: now ?? morning, calendar: istanbul, reminderCategories: reminders ?? [work])
    }
    func make(_ person: String?, _ action: String, _ due: Date?, category: UUID? = nil) -> TodoItem {
        let i = TodoItem(person: person, action: action, dueDate: due)
        i.categoryID = category ?? work
        return i
    }
    func teklif() -> TodoItem { make("X", "teklif at", date(2026, 10, 30)) }

    @Test func eveningNotificationsLastThreeDays() {
        let p = plan([teklif()])
        #expect(p.map(\.fireDate) == [date(2026, 10, 27, 20), date(2026, 10, 28, 20), date(2026, 10, 29, 20), date(2026, 10, 30, 10, 30)])
        #expect(p.map(\.title) == ["3 gün kaldı", "2 gün kaldı", "1 gün kaldı", "Bugün teslim"])
        #expect(p.allSatisfy { $0.body == "X · teklif at" })
    }
    @Test func pastTimesAreSkipped() {
        let p = plan([teklif()], now: date(2026, 10, 29, 21))
        #expect(p.map(\.fireDate) == [date(2026, 10, 30, 10, 30)])
    }
    @Test func undatedAndOverdueGoInDailyDigest() {
        let undated = make("Deniz", "ara", nil)
        let overdue = make("Ayşe", "faturayı gönder", date(2026, 10, 22))
        let p = plan([undated, overdue])
        #expect(p.count == 14)
        #expect(p[0].fireDate == date(2026, 10, 24, 12))
        #expect(p[0].body.contains("Deniz · ara") && p[0].body.contains("Ayşe · faturayı gönder"))
    }
    @Test func digestSkipsTodayWhenNoonPassed() {
        let undated = make("Deniz", "ara", nil)
        let p = plan([undated], now: date(2026, 10, 24, 13))
        #expect(p[0].fireDate == date(2026, 10, 25, 12))
    }
    @Test func noDigestWhenNothingPending() {
        #expect(plan([teklif()]).allSatisfy { !$0.id.hasPrefix("digest") })
    }
    @Test func doneItemsIgnored() {
        let t = teklif(); t.doneAt = morning
        #expect(plan([t]).isEmpty)
    }
    @Test func cappedAt60() {
        let items = (0..<100).map { make(nil, "iş \($0)", date(2026, 11, 1 + $0 % 28)) }
        let p = plan(items)
        #expect(p.count == 60)
        #expect(p == p.sorted { $0.fireDate < $1.fireDate })
    }
    @Test func idsAreStable() {
        let t = teklif()
        let a = plan([t]), b = plan([t])
        #expect(a.map(\.id) == b.map(\.id))
        #expect(a.first?.id == "item-\(t.id.uuidString)-evening-3")
    }
    @Test func nothingWithoutReminderCategories() {
        let uncategorized = TodoItem(person: "X", action: "ara", dueDate: date(2026, 10, 30))
        #expect(plan([uncategorized, teklif()], reminders: []).isEmpty)
    }
    @Test func onlyItemsOfReminderCategoriesNotify() {
        let other = make("Mert", "ders", date(2026, 10, 30), category: UUID())
        let p = plan([teklif(), other])
        #expect(p.count == 4)
        #expect(p.allSatisfy { $0.body == "X · teklif at" })
    }
}
