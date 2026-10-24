import Foundation

/// All items as CSV (open and done), for backup or invoicing outside the app.
public func csvExport(items: [TodoItem], categories: [TodoCategory], calendar: Calendar) -> String {
    let day = DateFormatter()
    day.calendar = calendar
    day.timeZone = calendar.timeZone
    day.locale = Locale(identifier: "en_US_POSIX")
    day.dateFormat = "yyyy-MM-dd"
    func field(_ text: String) -> String {
        text.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) ? "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\"" : text
    }
    var lines = ["Kişi,İş,Tarih,Saat,Kategori,Durum,Tamamlandı,Tekrar"]
    for item in items {
        let category = categories.first { $0.id == item.categoryID }?.name ?? ""
        let row = [
            item.person ?? "",
            item.action,
            item.dueDate.map(day.string) ?? "",
            item.dueMinutes.map(timeString) ?? "",
            category,
            item.isDone ? "Yapıldı" : "Açık",
            item.doneAt.map(day.string) ?? "",
            item.repeatRule ?? "",
        ]
        lines.append(row.map(field).joined(separator: ","))
    }
    return lines.joined(separator: "\n") + "\n"
}
