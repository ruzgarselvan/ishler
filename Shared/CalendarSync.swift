import EventKit
import Foundation
import TodoCore

/// Mirrors dated, open items into Apple Calendar as events (all-day, or 30 minutes at the item's time).
@MainActor
final class CalendarSync {
    private let store = EKEventStore()
    private var granted = false

    private func ensureAccess() async -> Bool {
        if !granted { granted = (try? await store.requestFullAccessToEvents()) ?? false }
        return granted
    }

    /// Creates, moves or deletes events so they match `items`. Idempotent.
    func sync(items: [TodoItem], calendar: Calendar) async {
        guard await ensureAccess() else { return }
        for item in items {
            let event = item.eventID.flatMap { store.event(withIdentifier: $0) }
            guard !item.isDone, let due = item.dueDate else {
                if let event { try? store.remove(event, span: .thisEvent) }
                item.eventID = nil
                continue
            }
            let target = event ?? EKEvent(eventStore: store)
            if event == nil { target.calendar = store.defaultCalendarForNewEvents }
            target.title = item.person.map { "\($0) · \(item.action)" } ?? item.action
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
        try? store.commit()
    }

    func remove(eventID: String?) async {
        guard let eventID, await ensureAccess(), let event = store.event(withIdentifier: eventID) else { return }
        try? store.remove(event, span: .thisEvent)
    }
}
