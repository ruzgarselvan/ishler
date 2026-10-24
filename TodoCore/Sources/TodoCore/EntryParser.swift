import Foundation

public struct ParsedEntry: Equatable, Sendable {
    public var person: String?
    public var action: String
    public var dueDate: Date?
    public var dateText: String?

    public init(person: String? = nil, action: String, dueDate: Date? = nil, dateText: String? = nil) {
        self.person = person
        self.action = action
        self.dueDate = dueDate
        self.dateText = dateText
    }
}

public struct EntryParser: Sendable {
    let knownPeople: [String]
    let calendar: Calendar

    public init(knownPeople: [String], calendar: Calendar) {
        self.knownPeople = knownPeople
        self.calendar = calendar
    }

    public func parse(_ text: String, now: Date) -> ParsedEntry {
        var tokens = text.split(whereSeparator: \.isWhitespace).map(String.init)
        var dueDate: Date?
        var dateText: String?

        if let match = resolveTurkishDate(tokens: tokens, now: now, calendar: calendar) {
            dueDate = match.date
            dateText = tokens[match.tokenRange].joined(separator: " ")
            tokens.removeSubrange(match.tokenRange)
        } else if let found = detectDate(in: text, now: now) {
            dueDate = found.date
            dateText = found.text
            tokens = text.replacingOccurrences(of: found.text, with: " ")
                .split(whereSeparator: \.isWhitespace).map(String.init)
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

        return ParsedEntry(
            person: person,
            action: tokens.joined(separator: " "),
            dueDate: dueDate,
            dateText: dateText
        )
    }

    private func detectDate(in text: String, now: Date) -> (date: Date, text: String)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue),
              let m = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let d = m.date, let r = Range(m.range, in: text) else { return nil }
        let day = calendar.startOfDay(for: d)
        return (day, String(text[r]))
    }
}
