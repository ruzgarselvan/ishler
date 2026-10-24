import Foundation

public struct ParsedEntry: Equatable, Sendable {
    public var person: String?
    public var action: String
    public var dueDate: Date?
    public var dateText: String?
    public var categoryID: UUID?
    public var dueMinutes: Int?
    public var repeatRule: String?
    public var checklist: [String]

    public init(person: String? = nil, action: String, dueDate: Date? = nil, dateText: String? = nil, categoryID: UUID? = nil,
                dueMinutes: Int? = nil, repeatRule: String? = nil, checklist: [String] = []) {
        self.person = person
        self.action = action
        self.dueDate = dueDate
        self.dateText = dateText
        self.categoryID = categoryID
        self.dueMinutes = dueMinutes
        self.repeatRule = repeatRule
        self.checklist = checklist
    }
}

public struct EntryParser: Sendable {
    let knownPeople: [String]
    let calendar: Calendar
    let categories: [TodoCategory]
    let shortcuts: ShortcutOptions
    let templates: [ChecklistTemplate]

    public init(knownPeople: [String], calendar: Calendar, categories: [TodoCategory] = [],
                shortcuts: ShortcutOptions = ShortcutOptions(), templates: [ChecklistTemplate] = []) {
        self.knownPeople = knownPeople
        self.calendar = calendar
        self.categories = categories
        self.shortcuts = shortcuts
        self.templates = templates
    }

    public func parse(_ text: String, now: Date) -> ParsedEntry {
        var tokens = text.split(whereSeparator: \.isWhitespace).map(String.init)
        var dueDate: Date?
        var dateText: String?
        var categoryID: UUID?

        if tokens.count > 1, let last = tokens.last, let category = matchShortcut(last) {
            categoryID = category.id
            tokens.removeLast()
        }

        var templateName: String?
        var checklist: [String] = []
        if let t = templates.first(where: { startsWith(tokens, name: $0.name) }) {
            tokens.removeFirst(t.name.split(whereSeparator: \.isWhitespace).count)
            templateName = t.name
            checklist = t.steps
        }

        let startOfToday = calendar.startOfDay(for: now)
        let repeatRule = extractRepeatRule(&tokens)
        let dueMinutes = extractTime(&tokens)

        if let match = resolveTurkishDate(tokens: tokens, now: now, calendar: calendar) {
            dueDate = match.date
            dateText = tokens[match.tokenRange].joined(separator: " ")
            tokens.removeSubrange(match.tokenRange)
        } else if tokens.isEmpty == false, case let remaining = tokens.joined(separator: " "),
                  let found = detectDate(in: remaining, now: now) {
            dueDate = found.date
            dateText = found.text
            tokens = remaining.replacingOccurrences(of: found.text, with: " ")
                .split(whereSeparator: \.isWhitespace).map(String.init)
        }

        if dueDate == nil {
            if let rule = repeatRule {
                dueDate = firstOccurrence(of: rule, from: startOfToday)
            }
            if let minutes = dueMinutes, dueDate == nil || dueDate == startOfToday {
                let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
                if minutes <= nowMinutes { dueDate = calendar.date(byAdding: .day, value: 1, to: startOfToday) }
                else if dueDate == nil { dueDate = startOfToday }
            }
        }

        tokens.removeAll { stem($0).hasPrefix("musteri") }

        var personIndex = tokens.firstIndex { token in
            knownPeople.contains { fold($0) == stem(token) }
        }
        var person = personIndex.flatMap { i in
            knownPeople.first { fold($0) == stem(tokens[i]) }
        }
        if personIndex == nil {
            personIndex = tokens.firstIndex { $0.contains("'") && $0.first?.isUppercase == true }
                ?? tokens.firstIndex { $0.first?.isUppercase == true }
            if let i = personIndex {
                person = String(tokens[i].split(whereSeparator: { $0 == "'" || $0 == "’" }).first ?? "")
            }
        }
        if let i = personIndex { tokens.remove(at: i) }

        let rest = tokens.joined(separator: " ")
        return ParsedEntry(
            person: person,
            action: templateName.map { rest.isEmpty ? $0 : "\($0) \(rest)" } ?? rest,
            dueDate: dueDate,
            dateText: dateText,
            categoryID: categoryID,
            dueMinutes: dueMinutes,
            repeatRule: repeatRule,
            checklist: checklist
        )
    }

    /// The bare shortcut ("x", "1") is always accepted; the parenthesized spelling "(x)" has its own toggle.
    private func matchShortcut(_ token: String) -> TodoCategory? {
        let t = fold(token)
        if t.count > 2, t.hasPrefix("("), t.hasSuffix(")") {
            guard shortcuts.parentheses else { return nil }
            let inner = String(t.dropFirst().dropLast())
            return categories.first { !$0.shortcut.isEmpty && fold($0.shortcut) == inner }
        }
        return categories.first { !$0.shortcut.isEmpty && fold($0.shortcut) == t }
    }

    private func startsWith(_ tokens: [String], name: String) -> Bool {
        let nameStems = name.split(whereSeparator: \.isWhitespace).map { stem(String($0)) }
        guard !nameStems.isEmpty, tokens.count >= nameStems.count else { return false }
        return zip(tokens, nameStems).allSatisfy { stem($0) == $1 }
    }

    /// "her gün", "her hafta", "her ay", "her yıl", "her pazartesi", "her ayın 1'i".
    private func extractRepeatRule(_ tokens: inout [String]) -> String? {
        let stems = tokens.map(stem)
        guard let i = stems.firstIndex(of: "her"), i + 1 < stems.count else { return nil }
        var rule: String?
        var length = 2
        switch stems[i + 1] {
        case "gun": rule = "daily"
        case "hafta": rule = "weekly"
        case "ay": rule = "monthly"
        case "yil": rule = "yearly"
        case "ayin":
            if i + 2 < stems.count, let day = Int(stems[i + 2]), (1...31).contains(day) { rule = "monthly:\(day)"; length = 3 }
        default:
            if let wd = weekdayNumber(stems[i + 1]) { rule = "weekly:\(wd)" }
        }
        guard let rule else { return nil }
        tokens.removeSubrange(i..<(i + length))
        return rule
    }

    /// "14:00", "14.30" or "saat 14" -> minutes since midnight.
    private func extractTime(_ tokens: inout [String]) -> Int? {
        for (i, token) in tokens.enumerated() {
            let parts = token.split(whereSeparator: { $0 == ":" || $0 == "." }).map(String.init)
            if parts.count == 2, parts[1].count == 2, let h = Int(parts[0]), let m = Int(parts[1]), h < 24, m < 60 {
                tokens.remove(at: i)
                return h * 60 + m
            }
            if stem(token) == "saat", i + 1 < tokens.count, let h = Int(stem(tokens[i + 1])), h < 24 {
                tokens.removeSubrange(i...(i + 1))
                return h * 60
            }
        }
        return nil
    }

    private func firstOccurrence(of rule: String, from today: Date) -> Date? {
        guard rule.contains(":"), let before = calendar.date(byAdding: .day, value: -1, to: today) else { return today }
        return nextOccurrence(after: before, rule: rule, calendar: calendar)
    }

    private func detectDate(in text: String, now: Date) -> (date: Date, text: String)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let m = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let d = m.date, let r = Range(m.range, in: text) else { return nil }
        let day = calendar.startOfDay(for: d)
        return (day, String(text[r]))
    }
}
