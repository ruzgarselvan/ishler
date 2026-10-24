import Foundation
import SwiftData

@Model
public final class TodoItem {
    public var id: UUID = UUID()
    public var person: String? = nil
    public var action: String = ""
    public var dueDate: Date? = nil
    public var createdAt: Date = Date()
    public var doneAt: Date? = nil
    public var categoryID: UUID? = nil
    /// Minutes since midnight when the item has a specific time.
    public var dueMinutes: Int? = nil
    public var repeatRule: String? = nil
    public var checklistData: Data? = nil
    /// EventKit identifier of the Apple Calendar event mirroring this item.
    public var eventID: String? = nil
    /// The scheduled routine ("Düzenli iş") that produced this item, so there is never more than one open copy.
    public var routineID: UUID? = nil

    public var isDone: Bool { doneAt != nil }

    public init(person: String?, action: String, dueDate: Date?) {
        self.person = person
        self.action = action
        self.dueDate = dueDate
    }
}
