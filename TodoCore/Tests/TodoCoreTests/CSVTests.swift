import Testing
import Foundation
@testable import TodoCore

@MainActor @Suite struct CSVTests {
    @Test func exportsOpenAndDoneItemsWithEscaping() {
        let cat = TodoCategory(name: "İş", shortcut: "x", colorHex: "#FF9500")
        let open = TodoItem(person: "Deniz", action: "ara, \"acil\"", dueDate: date(2026, 10, 30))
        open.dueMinutes = 14 * 60 + 30
        open.categoryID = cat.id
        open.repeatRule = "weekly"
        let done = TodoItem(person: nil, action: "fatura", dueDate: nil)
        done.doneAt = date(2026, 10, 24, 16)
        let csv = csvExport(items: [open, done], categories: [cat], calendar: istanbul)
        let lines = csv.split(separator: "\n").map(String.init)
        #expect(lines[0] == "Kişi,İş,Tarih,Saat,Kategori,Durum,Tamamlandı,Tekrar")
        #expect(lines[1] == "Deniz,\"ara, \"\"acil\"\"\",2026-10-30,14:30,İş,Açık,,weekly")
        #expect(lines[2] == ",fatura,,,,Yapıldı,2026-10-24,")
    }
}
