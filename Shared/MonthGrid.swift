import Foundation

/// Days of `month` padded with leading nils so the first day lands on its weekday column.
func monthDays(of month: Date, calendar cal: Calendar) -> [Date?] {
    guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
    let first = interval.start
    let offset = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
    let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
    return Array(repeating: nil, count: offset) + (0..<count).map { cal.date(byAdding: .day, value: $0, to: first) }
}
