import Foundation

/// The language the app is shown in (Turkish on Turkish systems, English otherwise), used for dates and weekday names.
let appLocale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")

/// One-letter weekday symbols in the calendar's week order ("M T W T F S S" or "P S Ç P C C P").
func weekdayInitials(_ calendar: Calendar) -> [String] {
    let symbols = calendar.veryShortStandaloneWeekdaySymbols
    let start = calendar.firstWeekday - 1
    return Array(symbols[start...] + symbols[..<start])
}
