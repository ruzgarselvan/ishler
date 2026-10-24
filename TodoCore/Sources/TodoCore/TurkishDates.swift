import Foundation

let turkish = Locale(identifier: "tr_TR")

/// Lowercased token without apostrophe suffix or trailing punctuation: "Cuma'ya" -> "cuma".
func stem(_ token: String) -> String {
    let lower = token.lowercased(with: turkish)
    let head = lower.split(whereSeparator: { $0 == "'" || $0 == "’" }).first.map(String.init) ?? lower
    return head.trimmingCharacters(in: .punctuationCharacters)
}

/// Matches `stem` against `names`, allowing a case suffix of up to 3 letters ("cumaya").
private func matchIndex(_ stem: String, in names: [String]) -> Int? {
    names.enumerated()
        .sorted { $0.element.count > $1.element.count }
        .first { stem == $0.element || (stem.hasPrefix($0.element) && stem.count - $0.element.count <= 3) }?
        .offset
}

private let weekdays = ["pazar", "pazartesi", "salı", "çarşamba", "perşembe", "cuma", "cumartesi"] // index+1 = Calendar weekday
private let months = ["ocak", "şubat", "mart", "nisan", "mayıs", "haziran", "temmuz", "ağustos", "eylül", "ekim", "kasım", "aralık"]

struct DateMatch {
    let date: Date
    let tokenRange: Range<Int>
}

/// Finds the first date expression in `tokens` using Turkish rules.
func resolveTurkishDate(tokens: [String], now: Date, calendar: Calendar) -> DateMatch? {
    let today = calendar.startOfDay(for: now)
    let stems = tokens.map(stem)

    func trailing(_ end: Int) -> Int {
        var end = end
        if end < stems.count, stems[end] == "günü" || stems[end] == "gün" { end += 1 }
        if end < stems.count, stems[end] == "kadar" { end += 1 }
        return end
    }
    func add(days: Int) -> Date { calendar.date(byAdding: .day, value: days, to: today)! }

    for i in stems.indices {
        let s = stems[i]
        if s == "bugün" { return DateMatch(date: today, tokenRange: i..<trailing(i + 1)) }
        if s == "yarın" { return DateMatch(date: add(days: 1), tokenRange: i..<trailing(i + 1)) }
        if s == "öbür", i + 1 < stems.count, stems[i + 1] == "gün" {
            return DateMatch(date: add(days: 2), tokenRange: i..<trailing(i + 2))
        }
        if s == "haftaya" || (s == "gelecek" && i + 1 < stems.count && stems[i + 1] == "hafta") {
            let wd = calendar.component(.weekday, from: today)
            var ahead = (2 - wd + 7) % 7
            if ahead == 0 { ahead = 7 }
            return DateMatch(date: add(days: ahead), tokenRange: i..<trailing(i + (s == "haftaya" ? 1 : 2)))
        }
        if let w = matchIndex(s, in: weekdays) {
            let wd = calendar.component(.weekday, from: today)
            return DateMatch(date: add(days: (w + 1 - wd + 7) % 7), tokenRange: i..<trailing(i + 1))
        }
        if let n = Int(s), i + 1 < stems.count {
            if let m = matchIndex(stems[i + 1], in: months), (1...31).contains(n) {
                var comps = calendar.dateComponents([.year], from: today)
                comps.month = m + 1
                comps.day = n
                guard var d = calendar.date(from: comps) else { continue }
                if d < today { d = calendar.date(byAdding: .year, value: 1, to: d)! }
                return DateMatch(date: d, tokenRange: i..<trailing(i + 2))
            }
            if stems[i + 1] == "gün", i + 2 < stems.count, stems[i + 2] == "sonra" {
                return DateMatch(date: add(days: n), tokenRange: i..<(i + 3))
            }
        }
    }
    return nil
}
