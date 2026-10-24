import Foundation

/// Rules: "daily", "weekly", "weekly:<Calendar weekday 1-7>", "monthly", "monthly:<day>", "yearly".
/// Returns the first occurrence strictly after `date`, or nil for an unknown rule.
public func nextOccurrence(after date: Date, rule: String, calendar: Calendar) -> Date? {
    let day = calendar.startOfDay(for: date)
    let parts = rule.split(separator: ":").map(String.init)
    switch (parts[0], parts.count > 1 ? Int(parts[1]) : nil) {
    case ("daily", _): return calendar.date(byAdding: .day, value: 1, to: day)
    case ("weekly", nil): return calendar.date(byAdding: .day, value: 7, to: day)
    case ("weekly", let weekday?):
        return (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: day) }
            .first { calendar.component(.weekday, from: $0) == weekday }
    case ("monthly", nil): return calendar.date(byAdding: .month, value: 1, to: day)
    case ("monthly", let dom?):
        for offset in 0...1 {
            guard let month = calendar.date(byAdding: .month, value: offset, to: day),
                  let interval = calendar.dateInterval(of: .month, for: month),
                  let length = calendar.range(of: .day, in: .month, for: month)?.count,
                  let candidate = calendar.date(byAdding: .day, value: min(dom, length) - 1, to: interval.start),
                  candidate > day else { continue }
            return candidate
        }
        return nil
    case ("yearly", _): return calendar.date(byAdding: .year, value: 1, to: day)
    default: return nil
    }
}
