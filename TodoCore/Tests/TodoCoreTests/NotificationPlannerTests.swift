import Testing
import Foundation
@testable import TodoCore

@Suite struct NotificationPlannerTests {
    let settings = NotificationSettings.default
    let morning = date(2026, 10, 24, 9)
    let work = UUID()

    func plan(_ items: [TodoItem], now: Date? = nil, reminders: Set<UUID>? = nil, lastActivity: Date? = nil) -> [PlannedNotification] {
        planNotifications(items: items, settings: settings, now: now ?? morning, calendar: istanbul,
                          reminderCategories: reminders ?? [work], lastActivity: lastActivity ?? now ?? morning)
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
        #expect(p.allSatisfy { $0.title == "X · teklif at" })
        #expect(p.map(\.body) == ["30 Ekim · 3 gün kaldı", "30 Ekim · 2 gün kaldı", "Yarın", "Bugün"])
    }
    @Test func pastTimesAreSkipped() {
        let p = plan([teklif()], now: date(2026, 10, 29, 21))
        #expect(p.map(\.fireDate) == [date(2026, 10, 30, 10, 30)])
    }
    @Test func digestWaitsForTwoInactiveDays() {
        let undated = make("Deniz", "ara", nil)
        let overdue = make("Ayşe", "faturayı gönder", date(2026, 10, 22))
        let p = plan([undated, overdue])
        #expect(p.count == 14)
        #expect(p[0].fireDate == date(2026, 10, 26, 12))
        #expect(p[0].title == "Seni bekleyen işler var!")
        #expect(p[0].body == "Deniz · ara\nAyşe · faturayı gönder · 4 gün önce")
        #expect(p[1].body == "Deniz · ara\nAyşe · faturayı gönder · 5 gün önce")
    }
    @Test func digestStartsFromLastActivityNotFromNow() {
        let undated = make("Deniz", "ara", nil)
        let p = plan([undated], now: date(2026, 10, 24, 9), lastActivity: date(2026, 10, 20, 18))
        #expect(p[0].fireDate == date(2026, 10, 24, 12))
        #expect(p.count == 12)
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
        #expect(p.allSatisfy { $0.title == "X · teklif at" })
    }
    @Test func timedItemNotifiesAtItsTimeInsteadOfMorning() {
        let item = make("Deniz", "ara", date(2026, 10, 30))
        item.dueMinutes = 14 * 60
        let p = plan([item])
        #expect(p.map(\.fireDate) == [date(2026, 10, 27, 20), date(2026, 10, 28, 20), date(2026, 10, 29, 20), date(2026, 10, 30, 14)])
        #expect(p.map(\.body) == ["30 Ekim 14:00 · 3 gün kaldı", "30 Ekim 14:00 · 2 gün kaldı", "Yarın 14:00", "Şimdi · 14:00"])
    }
    @Test func itemNotificationsCarryItemIDButDigestDoesNot() {
        let item = teklif()
        let undated = make("Deniz", "ara", nil)
        let p = plan([item, undated])
        #expect(p.filter { $0.id.hasPrefix("item-") }.allSatisfy { $0.itemID == item.id })
        #expect(p.filter { $0.id.hasPrefix("digest") }.allSatisfy { $0.itemID == nil })
    }
}
