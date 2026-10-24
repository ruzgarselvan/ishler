import Foundation

let turkish = Locale(identifier: "tr_TR")

/// Lowercased with Turkish letters folded to ASCII, so "Kasım" and "kasim" compare equal.
func fold(_ text: String) -> String {
    String(text.lowercased(with: turkish).map { c -> Character in
        switch c {
        case "ı": "i"
        case "ş": "s"
        case "ç": "c"
        case "ğ": "g"
        case "ö": "o"
        case "ü": "u"
        default: c
        }
    })
}

/// Folded token without apostrophe suffix or trailing punctuation: "Cuma'ya" -> "cuma".
func stem(_ token: String) -> String {
    let lower = fold(token)
    let head = lower.split(whereSeparator: { $0 == "'" || $0 == "’" }).first.map(String.init) ?? lower
    return head.trimmingCharacters(in: .punctuationCharacters)
}

/// Matches `stem` against folded names, allowing a case suffix of up to 3 letters ("cumaya", "fridays").
private func matchName(_ stem: String, in names: [(String, Int)]) -> Int? {
    names.sorted { $0.0.count > $1.0.count }
        .first { stem == $0.0 || (stem.hasPrefix($0.0) && stem.count - $0.0.count <= 3) }?.1
}

/// Calendar weekday (1 = Sunday ... 7 = Saturday) for a folded Turkish or English weekday name.
func weekdayNumber(_ stem: String) -> Int? { matchName(stem, in: weekdayNames) }

private let weekdayNames: [(String, Int)] = [
    ("pazar", 1), ("pazartesi", 2), ("sali", 3), ("carsamba", 4), ("persembe", 5), ("cuma", 6), ("cumartesi", 7),
    ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4), ("thursday", 5), ("friday", 6), ("saturday", 7),
]
private let monthNames: [(String, Int)] = [
    ("ocak", 1), ("subat", 2), ("mart", 3), ("nisan", 4), ("mayis", 5), ("haziran", 6), ("temmuz", 7), ("agustos", 8),
    ("eylul", 9), ("ekim", 10), ("kasim", 11), ("aralik", 12),
    ("january", 1), ("february", 2), ("march", 3), ("april", 4), ("may", 5), ("june", 6), ("july", 7), ("august", 8),
    ("september", 9), ("october", 10), ("november", 11), ("december", 12),
]

private let numberWords: [String: Int] = [
    "bir": 1, "iki": 2, "uc": 3, "dort": 4, "bes": 5, "alti": 6, "yedi": 7, "sekiz": 8, "dokuz": 9,
    "on": 10, "onbes": 15, "yirmi": 20, "otuz": 30,
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "fifteen": 15, "twenty": 20, "thirty": 30,
]

/// "3", "24th", "three", "uc" -> number.
private func number(_ stem: String) -> Int? {
    if let n = Int(stem) { return n }
    for suffix in ["st", "nd", "rd", "th"] where stem.hasSuffix(suffix) {
        if let n = Int(stem.dropLast(2)) { return n }
    }
    return numberWords[stem]
}

private func unit(_ stem: String) -> Calendar.Component? {
    switch stem {
    case "gun", "day", "days": .day
    case "hafta", "week", "weeks": .weekOfYear
    case "ay", "month", "months": .month
    default: nil
    }
}

struct DateMatch {
    let date: Date
    let tokenRange: Range<Int>
}

/// Words that introduce a date ("by Friday", "on Monday") and are dropped with it.
private let datePrefixes: Set<String> = ["by", "on", "until", "due", "before"]

/// Finds the first date expression in `tokens` (Turkish or English).
func resolveTurkishDate(tokens: [String], now: Date, calendar: Calendar) -> DateMatch? {
    let today = calendar.startOfDay(for: now)
    let stems = tokens.map(stem)

    func trailing(_ end: Int) -> Int {
        var end = end
        if end < stems.count, stems[end] == "gunu" || stems[end] == "gun" { end += 1 }
        if end < stems.count, stems[end] == "kadar" { end += 1 }
        return end
    }
    func add(days: Int) -> Date { calendar.date(byAdding: .day, value: days, to: today)! }
    func match(_ date: Date, _ start: Int, _ end: Int) -> DateMatch {
        let from = start > 0 && datePrefixes.contains(stems[start - 1]) ? start - 1 : start
        return DateMatch(date: date, tokenRange: from..<end)
    }
    func nextMonday() -> Date {
        let wd = calendar.component(.weekday, from: today)
        var ahead = (2 - wd + 7) % 7
        if ahead == 0 { ahead = 7 }
        return add(days: ahead)
    }
    func dayOfMonth(_ day: Int, month: Int) -> Date? {
        var comps = calendar.dateComponents([.year], from: today)
        comps.month = month
        comps.day = day
        guard var d = calendar.date(from: comps) else { return nil }
        if d < today { d = calendar.date(byAdding: .year, value: 1, to: d)! }
        return d
    }

    for i in stems.indices {
        let s = stems[i]
        let next = i + 1 < stems.count ? stems[i + 1] : ""
        if s == "bugun" { return match(today, i, trailing(i + 1)) }
        if s == "today" || s == "tonight" { return match(today, i, i + 1) }
        if s == "yarin" { return match(add(days: 1), i, trailing(i + 1)) }
        if s == "tomorrow" { return match(add(days: 1), i, i + 1) }
        if s == "obur", next == "gun" { return match(add(days: 2), i, trailing(i + 2)) }
        if s == "day", next == "after", i + 2 < stems.count, stems[i + 2] == "tomorrow" { return match(add(days: 2), i, i + 3) }
        if s == "haftaya" { return match(nextMonday(), i, trailing(i + 1)) }
        if (s == "gelecek" && next == "hafta") { return match(nextMonday(), i, trailing(i + 2)) }
        if s == "next", next == "week" { return match(nextMonday(), i, i + 2) }
        if s == "in", let n = number(next), i + 2 < stems.count, let u = unit(stems[i + 2]),
           let d = calendar.date(byAdding: u, value: n, to: today) {
            return match(d, i, i + 3)
        }
        if let w = weekdayNumber(s) {
            let wd = calendar.component(.weekday, from: today)
            var offset = (w - wd + 7) % 7
            let qualified = i > 0 && ["next", "this"].contains(stems[i - 1])
            if i > 0, stems[i - 1] == "next", offset == 0 { offset = 7 }
            return match(add(days: offset), qualified ? i - 1 : i, trailing(i + 1))
        }
        if let m = matchName(s, in: monthNames), let n = number(next), (1...31).contains(n), let d = dayOfMonth(n, month: m) {
            return match(d, i, i + 2)
        }
        if let n = number(s), i + 1 < stems.count {
            let monthIndex = next == "of" ? i + 2 : i + 1
            if monthIndex < stems.count, let m = matchName(stems[monthIndex], in: monthNames), (1...31).contains(n),
               let d = dayOfMonth(n, month: m) {
                return match(d, i, trailing(monthIndex + 1))
            }
            if i + 2 < stems.count, stems[i + 2] == "sonra", let u = unit(next), let d = calendar.date(byAdding: u, value: n, to: today) {
                return match(d, i, i + 3)
            }
        }
    }
    return nil
}
