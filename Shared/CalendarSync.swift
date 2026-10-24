import EventKit
import Foundation
import TodoCore

/// Mirrors dated, open items into Apple Calendar as events (all-day, or 30 minutes at the item's time).
/// Every event it writes carries `ishler:<task id>` in its notes, so events are found again after a reinstall or on
/// another device, duplicates are merged, and events whose task is gone are removed. Other events are never touched.
@MainActor
final class CalendarSync {
    static let marker = "ishler:"
    private let store = EKEventStore()
    private var granted = false

    private func ensureAccess() async -> Bool {
        if !granted { granted = (try? await store.requestFullAccessToEvents()) ?? false }
        return granted
    }

    static func taskID(of event: EKEvent) -> UUID? {
        guard let notes = event.notes, notes.hasPrefix(marker) else { return nil }
        return UUID(uuidString: String(notes.dropFirst(marker.count).prefix(36)))
    }

    /// Creates, moves or deletes events so they match `items`. Idempotent.
    func sync(items: [TodoItem], calendar: Calendar, now: Date = Date()) async {
        guard await ensureAccess() else { return }
        let from = calendar.date(byAdding: .day, value: -30, to: now)!
        let to = calendar.date(byAdding: .day, value: 400, to: now)!
        let ours = store.events(matching: store.predicateForEvents(withStart: from, end: to, calendars: nil))
            .compactMap { e in Self.taskID(of: e).map { ($0, e) } }
        var byTask = Dictionary(grouping: ours, by: \.0).mapValues { $0.map(\.1) }

        for item in items {
            var events = byTask.removeValue(forKey: item.id) ?? []
            if events.isEmpty, let id = item.eventID, let known = store.event(withIdentifier: id) { events = [known] }
            let wanted = !item.isDone && item.dueDate != nil
            // Keep one event per task; remove extras, and everything if the task no longer needs one.
            for extra in (wanted ? Array(events.dropFirst()) : events) { try? store.remove(extra, span: .thisEvent) }
            guard wanted, let due = item.dueDate else { item.eventID = nil; continue }

            let target = events.first ?? EKEvent(eventStore: store)
            if events.isEmpty { target.calendar = store.defaultCalendarForNewEvents }
            target.title = item.person.map { "\($0) · \(item.action)" } ?? item.action
            target.notes = Self.marker + item.id.uuidString
            let day = calendar.startOfDay(for: due)
            if let minutes = item.dueMinutes {
                target.isAllDay = false
                target.startDate = calendar.date(byAdding: .minute, value: minutes, to: day)
                target.endDate = target.startDate.addingTimeInterval(30 * 60)
            } else {
                target.isAllDay = true
                target.startDate = day
                target.endDate = day
            }
            if (try? store.save(target, span: .thisEvent)) != nil { item.eventID = target.eventIdentifier }
        }
        // Whatever is left belongs to tasks that no longer exist.
        for orphan in byTask.values.flatMap({ $0 }) { try? store.remove(orphan, span: .thisEvent) }
        try? store.commit()
    }

    func remove(eventID: String?) async {
        guard let eventID, await ensureAccess(), let event = store.event(withIdentifier: eventID) else { return }
        try? store.remove(event, span: .thisEvent)
    }
}
