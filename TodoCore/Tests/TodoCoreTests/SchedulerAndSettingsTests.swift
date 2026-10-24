import Testing
import Foundation
@testable import TodoCore

@MainActor final class FakeCenter: NotificationCenterProtocol {
    var log: [String] = []
    func removeAllPending() { log.append("clear") }
    func add(_ n: PlannedNotification, calendar: Calendar) async { log.append("add") }
}

@MainActor @Suite struct SchedulerAndSettingsTests {
    @Test func rescheduleReplacesPending() async {
        let center = FakeCenter()
        let scheduler = NotificationScheduler(center: center)
        let item = TodoItem(person: "X", action: "teklif", dueDate: date(2026, 10, 30))
        for _ in 0..<2 {
            await scheduler.reschedule(items: [item], settings: .default, now: date(2026, 10, 24, 9), calendar: istanbul)
        }
        #expect(center.log == ["clear", "add", "add", "add", "add", "clear", "add", "add", "add", "add"])
    }
    @Test func settingsDefaultAndRoundTrip() {
        let suite = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let a = SettingsStore(defaults: suite)
        #expect(a.settings == .default)
        a.settings.eveningTime = DateComponents(hour: 21, minute: 15)
        let b = SettingsStore(defaults: suite)
        #expect(b.settings.eveningTime == DateComponents(hour: 21, minute: 15))
    }
}
