import EventKit
import Foundation
import Observation

/// Read-only view of the user's Apple Calendar events, grouped by start day.
@Observable @MainActor
final class EventsProvider {
    private let store = EKEventStore()
    private var granted = false
    private(set) var byDay: [Date: [EKEvent]] = [:]

    /// Events on `day`, without the ones this app wrote itself (those are already shown as tasks).
    func events(on day: Date, calendar: Calendar, excluding ownIDs: Set<String>) -> [EKEvent] {
        (byDay[calendar.startOfDay(for: day)] ?? []).filter { !ownIDs.contains($0.eventIdentifier) }
    }

    func load(month: Date, calendar: Calendar) async {
        if !granted { granted = (try? await store.requestFullAccessToEvents()) ?? false }
        guard granted, let interval = calendar.dateInterval(of: .month, for: month) else { byDay = [:]; return }
        let predicate = store.predicateForEvents(withStart: interval.start, end: interval.end, calendars: nil)
        byDay = Dictionary(grouping: store.events(matching: predicate)) { calendar.startOfDay(for: $0.startDate) }
    }
}
