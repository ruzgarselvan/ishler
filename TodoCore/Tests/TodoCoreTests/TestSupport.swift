import Foundation

let istanbul: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "Europe/Istanbul")!
    c.locale = Locale(identifier: "tr_TR")
    c.firstWeekday = 2
    return c
}()

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    istanbul.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}
