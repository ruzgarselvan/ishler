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
}
