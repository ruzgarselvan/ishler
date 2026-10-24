import Testing
import Foundation
@testable import TodoCore

@MainActor @Suite struct HorizonTests {
    func visible(_ due: Date?, _ h: Horizon) -> Bool {
        isVisible(TodoItem(person: nil, action: "x", dueDate: due), horizon: h, now: date(2026, 10, 24, 15), calendar: istanbul)
    }
    @Test func undatedAndOverdueAlwaysVisible() {
        for h in Horizon.allCases {
            #expect(visible(nil, h))
            #expect(visible(date(2026, 10, 1), h))
        }
    }
    @Test func weekHidesAfterSevenDays() {
        #expect(visible(date(2026, 10, 31), .week))
        #expect(!visible(date(2026, 11, 1), .week))
    }
    @Test func monthHidesAfterThirtyOneDays() {
        #expect(visible(date(2026, 11, 24), .month))
        #expect(!visible(date(2026, 11, 25), .month))
    }
    @Test func allShowsEverything() {
        #expect(visible(date(2027, 5, 1), .all))
    }
    @Test func horizonPersists() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.horizon == .month)
        a.horizon = .week
        #expect(SettingsStore(defaults: suite).horizon == .week)
    }
    @Test func menuBarStyleDefaultsToCountAndPersists() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.menuBarStyle == .count)
        a.menuBarStyle = .title
        #expect(SettingsStore(defaults: suite).menuBarStyle == .title)
    }
    @Test func legacyBadgeOffBecomesMenuBarOff() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        suite.set(false, forKey: "showBadge")
        #expect(SettingsStore(defaults: suite).menuBarStyle == .off)
    }
    @Test func newTogglesDefaultOnAndTemplateSeeded() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.writeToCalendar && a.quickAddHotkey)
        #expect(a.templates.map(\.name) == ["Çekim sonrası"])
        a.templates.removeAll()
        #expect(SettingsStore(defaults: suite).templates.isEmpty)
    }
    @Test func categoriesAndShortcutsPersist() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.shortcuts == ShortcutOptions())
        let c = TodoCategory(name: "Özel", shortcut: "z", colorHex: "#FF9500", remind: true)
        a.categories = [c]
        a.shortcuts.parentheses = false
        let b = SettingsStore(defaults: suite)
        #expect(b.categories == [c])
        #expect(!b.shortcuts.parentheses)
        #expect(b.category(c.id)?.name == "Özel")
    }
    @Test func defaultCategoriesSeededOnceAndRemindersOff() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.categories.map(\.name) == ["İş", "Okul", "Kişisel"])
        #expect(a.categories.allSatisfy { !$0.remind })
        a.categories.removeAll()
        #expect(SettingsStore(defaults: suite).categories.isEmpty)
    }
    @Test func oldSavedCategoriesWithoutRemindFieldStillLoad() throws {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let id = UUID()
        let json = "[{\"id\":\"\(id.uuidString)\",\"name\":\"Eski\",\"shortcut\":\"e\",\"colorHex\":\"#007AFF\"}]"
        suite.set(Data(json.utf8), forKey: "categories")
        let c = SettingsStore(defaults: suite).categories
        #expect(c.count == 1 && c[0].name == "Eski" && !c[0].remind)
    }
    @Test func appearanceDefaultsToSystemAndPersists() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.appearance == .system)
        a.appearance = .dark
        #expect(SettingsStore(defaults: suite).appearance == .dark)
    }
    @Test func appModeDefaultsToMenuBarAndPersists() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.appMode == .menuBar)
        a.appMode = .both
        #expect(SettingsStore(defaults: suite).appMode == .both)
    }
}
