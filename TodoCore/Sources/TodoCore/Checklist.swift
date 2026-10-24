import Foundation

public struct ChecklistEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var title: String
    public var done: Bool

    public init(id: UUID = UUID(), title: String, done: Bool = false) {
        self.id = id
        self.title = title
        self.done = done
    }
}

/// A named routine ("Düzenli iş"): steps typed after its name at the start of a note, and optionally a schedule
/// ("monthly:15", "weekly:2", "daily") that makes the app put the task on the list by itself.
public struct ChecklistTemplate: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var steps: [String]
    public var schedule: String?
    public var categoryID: UUID?

    public init(id: UUID = UUID(), name: String, steps: [String], schedule: String? = nil, categoryID: UUID? = nil) {
        self.id = id
        self.name = name
        self.steps = steps
        self.schedule = schedule
        self.categoryID = categoryID
    }

    /// Routines saved before schedules existed decode as unscheduled.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        steps = try c.decode([String].self, forKey: .steps)
        schedule = try c.decodeIfPresent(String.self, forKey: .schedule)
        categoryID = try c.decodeIfPresent(UUID.self, forKey: .categoryID)
    }
}

extension ChecklistTemplate {
    /// Shipped so the feature is discoverable; users can edit or delete it.
    public static let example = ChecklistTemplate(
        name: String(localized: "Çekim sonrası"),
        steps: [String(localized: "Dosyaları yedekle"), String(localized: "Seçimi yap"), String(localized: "Düzenlemeye başla"),
                String(localized: "Müşteriye teslim et"), String(localized: "Faturayı kes")]
    )
}

extension TodoItem {
    public var checklist: [ChecklistEntry] {
        get { checklistData.flatMap { try? JSONDecoder().decode([ChecklistEntry].self, from: $0) } ?? [] }
        set { checklistData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue) }
    }
}
