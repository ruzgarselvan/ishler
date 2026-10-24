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

    public var isDone: Bool { doneAt != nil }

    public init(person: String?, action: String, dueDate: Date?) {
        self.person = person
        self.action = action
        self.dueDate = dueDate
    }
}
