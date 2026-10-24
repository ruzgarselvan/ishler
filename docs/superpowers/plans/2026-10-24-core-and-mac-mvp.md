# Çekirdek + Mac menü bar MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mac menü bar'da cümle yazarak iş ekleme, tarihe göre liste, "yapıldı"/arşiv ve yerel bildirimlerin çalıştığı ilk sürüm.

**Architecture:** Tüm mantık (model, cümle ayrıştırma, bucket'lama, bildirim planı) `TodoCore` adlı bir Swift paketinde, UI'dan bağımsız ve `swift test` ile test edilir. Mac uygulaması (`MenuBarTodo`) bu paketi kullanan ince bir SwiftUI `MenuBarExtra` katmanıdır. iPhone, Apple Takvim, iCloud ve abonelik **bu planda yok**, sonraki planlarda gelir; model baştan CloudKit uyumlu yazılır.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, UserNotifications, XcodeGen (proje dosyası için), Swift Testing (`import Testing`).

**Spec:** `docs/superpowers/specs/2026-10-24-menubar-todo-design.md`

## Scope

Spec beş bağımsız parçaya ayrılır; her biri kendi planını alır: (1) bu plan, (2) Apple Takvim okuma/yazma + takvim penceresi, (3) iPhone uygulaması + iCloud senkronu, (4) StoreKit aboneliği + deneme sonrası kısıtlı mod, (5) App Store yayın rehberi. Bu plan sonunda tek başına kullanılabilir bir Mac uygulaması çıkar.

## Global Constraints

- Arayüz dili Türkçe; tarih/saat işlemleri `Locale(identifier: "tr_TR")` ve `Europe/Istanbul` ile test edilir.
- Sunucu, hesap, yapay zekâ servisi yok.
- `TodoItem` CloudKit uyumlu: tüm alanların varsayılanı var, `@Attribute(.unique)` yok, ilişki yok.
- Tarihsiz iş "Bugün" grubunda durur, kullanıcı "yapıldı" diyene kadar kalır; hiçbir şey kendiliğinden ertelenmez veya silinmez.
- Yapıldı işler silinmez, `doneAt` ile arşivlenir, dokununca geri açılır.
- Bildirim varsayılanları: son 3 gün her akşam 20:00, teslim günü sabah 10:30, tarihsiz/gecikmiş işler için her gün 12:00. Hepsi ayarlanabilir.
- Görsel dil: buzlu cam (`.glassEffect`/`.ultraThinMaterial`), SF fontu, sistem renkleri. Kişi adı yalnızca `.fontWeight(.semibold)`. Tek vurgu rengi: gecikmiş tarih `.red`, birincil buton `.accentColor`. Sarı vurgu yok. Arşiv ekranı sade, yoğun, tek satırlık liste.
- Minimum platform: macOS 26 (Liquid Glass için).

## Review Focus

- "Cuma" yazıldığı gün Cuma ise: bugün sayılır (gelecek haftaya atlamaz).
- "Cuma'ya kadar" ve "cuma günü" gibi ek/varyantlar aynı tarihi verir; büyük/küçük harf fark etmez ("CUMA", "cuma").
- Tarih bulunamayan cümle hata vermez, `dueDate == nil` döner; boş veya sadece boşluk cümle eklenmez.
- Kişi bulunamayan cümle ("faturayı gönder") hata vermez, `person == nil`.
- 64 bekleyen yerel bildirim sınırı: plan en fazla 60 bildirim döndürür, en yakın tarihliler öncelikli.
- Gece yarısı/saat dilimi/yaz saati: "Bugün" ve "Gecikmiş" sınırı takvim gününe göre, 24 saate göre değil.

---

### Task 1: Paket iskeleti ve TodoItem + bucket'lama

**Files:**
- Create: `TodoCore/Package.swift`, `TodoCore/Sources/TodoCore/TodoItem.swift`, `TodoCore/Sources/TodoCore/Bucket.swift`
- Test: `TodoCore/Tests/TodoCoreTests/BucketTests.swift`
- Create: `.gitignore` (`.build/`, `.superpowers/`, `*.xcodeproj`)

**Interfaces:**
- Produces:
  - `@Model public final class TodoItem` — `var id: UUID = UUID()`, `var person: String? = nil`, `var action: String = ""`, `var dueDate: Date? = nil`, `var createdAt: Date = Date()`, `var doneAt: Date? = nil`; `public init(person: String?, action: String, dueDate: Date?)`; `var isDone: Bool { doneAt != nil }`
  - `public enum Bucket: Int, Comparable { case overdue, today, thisWeek, later }`
  - `public func bucket(for item: TodoItem, now: Date, calendar: Calendar) -> Bucket`
  - `public func sortedOpenItems(_ items: [TodoItem], now: Date, calendar: Calendar) -> [(Bucket, [TodoItem])]` — yalnızca açık işler, bucket sırasıyla; bucket içinde tarihsizler sona, tarihliler artan sırada; boş bucket'lar dönmez.

- [ ] **Step 1:** `git init`, `.gitignore` yaz, `TodoCore/Package.swift` oluştur (platforms: `.macOS("26.0")`, `.iOS("26.0")`; library `TodoCore`; test target).
- [ ] **Step 2: Write the failing tests** in `BucketTests.swift`, takvim `tr_TR`/`Europe/Istanbul`, `now` = 2026-10-24 (Cumartesi) 15:00:
  - `undatedItemIsToday`: dueDate nil → `.today`
  - `yesterdayIsOverdue`: 2026-10-23 → `.overdue`
  - `todayLateEveningIsToday`: 2026-10-24 23:59 → `.today`
  - `nextFridayIsThisWeek`: 2026-10-30 → `.thisWeek`
  - `eightDaysAheadIsLater`: 2026-11-01 → `.later`
  - `doneItemsExcluded`: `sortedOpenItems` doneAt dolu işi dönmez
  - `undatedSortsAfterDatedInToday`: bugün tarihli iş, tarihsiz işten önce gelir
- [ ] **Step 3: Run** `cd TodoCore && swift test` — Expected: derleme hatası/FAIL (tipler yok).
- [ ] **Step 4: Implement** yukarıdaki imzaları. "thisWeek" = yarından itibaren 7 takvim günü içi; sınır `calendar.startOfDay` farkıyla hesaplanır.
- [ ] **Step 5: Run** `swift test` — Expected: tüm testler PASS.
- [ ] **Step 6: Commit** — `git add -A && git commit -m "feat: TodoItem ve bucket'lama"`

### Task 2: Türkçe cümle ayrıştırıcı

**Files:**
- Create: `TodoCore/Sources/TodoCore/EntryParser.swift`, `TodoCore/Sources/TodoCore/TurkishDates.swift`
- Test: `TodoCore/Tests/TodoCoreTests/EntryParserTests.swift`

**Interfaces:**
- Consumes: yok.
- Produces:
  - `public struct ParsedEntry: Equatable { public var person: String?; public var action: String; public var dueDate: Date?; public var dateText: String? }`
  - `public struct EntryParser { public init(knownPeople: [String], calendar: Calendar); public func parse(_ text: String, now: Date) -> ParsedEntry }`
  - `func resolveTurkishDate(in text: String, now: Date, calendar: Calendar) -> (date: Date, matched: Range<String.Index>)?` (`TurkishDates.swift`, internal)

- [ ] **Step 1: Write the failing tests** (`now` = 2026-10-24 Cumartesi 15:00, tr_TR/Istanbul):
  - `fullSentence`: `"Cuma'ya kadar X müşterisine teklif at"` → person `"X"`, action `"teklif at"`, dueDate 2026-10-30, dateText `"Cuma'ya kadar"`
  - `noDate`: `"Deniz'i ara"` → person `"Deniz"`, action `"ara"`, dueDate nil
  - `noPerson`: `"yarın faturayı gönder"` → person nil, action `"faturayı gönder"`, dueDate 2026-10-25
  - `fridayOnFriday`: now Cuma 2026-10-30, `"Cuma'ya X'e teklif at"` → dueDate 2026-10-30 (aynı gün)
  - `caseInsensitive`: `"CUMA günü Ayşe fatura"` → 2026-10-30
  - `knownPersonWins`: knownPeople `["Mert"]`, `"mert revizyon"` → person `"Mert"`, action `"revizyon"`
  - `explicitDate`: `"15 Kasım'a kadar Mert logo"` → 2026-11-15, person `"Mert"`, action `"logo"`
  - `relativeWeek`: `"gelecek hafta Deniz'i ara"` → Pazartesi 2026-10-26
  - `emptyInput`: `"   "` → action `""` (çağıran eklemez)
  - Tarih kuralları: bugün, yarın, öbür gün, hafta içi gün adları (+ek/"günü"/"kadar"), "gelecek hafta", "N Ay" (Türkçe ay adları), "N gün sonra".
- [ ] **Step 2: Run** `swift test --filter EntryParserTests` — Expected: FAIL.
- [ ] **Step 3: Implement** `resolveTurkishDate` önce kendi kurallarla (küçük harfe `tr_TR` locale ile çevirip eşle; ek ve "kadar/günü" dahil eşleşen aralığı döndür), eşleşme yoksa `NSDataDetector(.date)` yedeği. `EntryParser.parse`: (1) tarih aralığını çıkar, (2) kalan metinde `knownPeople` eşleşmesi (büyük/küçük harf duyarsız) varsa kişi o, yoksa ilk büyük harfli kelime (cümle başı tarihten sonra kalan ilk kelime dahil değil; ekleri `'` sonrasından atarak) kişi, (3) "müşteri/müşterisi/müşterisine" ve tırnak sonrası ekleri at, (4) kalanı `action` yap, baş/son boşlukları temizle. Küçük harfle yazılmış bilinmeyen isim kişi sayılmaz (bilinçli sınır).
- [ ] **Step 4: Run** — Expected: PASS. Başarısız olan Türkçe ifadeleri `TurkishDates.swift` kurallarına ekle, hiçbir testi gevşetme.
- [ ] **Step 5: Commit** — `git commit -am "feat: Türkçe cümle ayrıştırıcı"`

### Task 3: Bildirim planlayıcı

**Files:**
- Create: `TodoCore/Sources/TodoCore/NotificationPlanner.swift`
- Test: `TodoCore/Tests/TodoCoreTests/NotificationPlannerTests.swift`

**Interfaces:**
- Consumes: `TodoItem`, `Bucket` (Task 1).
- Produces:
  - `public struct NotificationSettings: Codable, Equatable { public var eveningTime: DateComponents; public var morningTime: DateComponents; public var digestTime: DateComponents; public var eveningDaysBefore: Int; public static let `default`: NotificationSettings }` — varsayılan 20:00 / 10:30 / 12:00 / 3
  - `public struct PlannedNotification: Equatable { public let id: String; public let fireDate: Date; public let title: String; public let body: String }`
  - `public func planNotifications(items: [TodoItem], settings: NotificationSettings, now: Date, calendar: Calendar) -> [PlannedNotification]`

- [ ] **Step 1: Write the failing tests** (`now` = 2026-10-24 Cumartesi 09:00):
  - `eveningNotificationsLastThreeDays`: Cuma 2026-10-30 teslimli iş → 27, 28, 29 Ekim 20:00 + 30 Ekim 10:30 (toplam 4); başlık `"Cuma'ya 3 gün kaldı"`/`"2 gün kaldı"`/`"1 gün kaldı"`, gövde `"X · teklif at"`; teslim günü başlığı `"Bugün teslim"`
  - `pastTimesAreSkipped`: now 2026-10-29 21:00 → yalnız 30 Ekim 10:30
  - `undatedAndOverdueGoInDailyDigest`: tarihsiz "Deniz · ara" + gecikmiş iş → bugünden başlayıp her gün 12:00 tek bildirim, gövdede ikisi; ilk digest 12:00 geçtiyse ertesi gün
  - `noDigestWhenNothingPending`: tarihsiz/gecikmiş yoksa digest yok
  - `doneItemsIgnored`
  - `cappedAt60`: 100 tarihli iş → `count <= 60`, en yakın `fireDate`'ler tutulur
  - `idsAreStable`: aynı girdi → aynı id'ler (`"item-<uuid>-evening-1"`, `"digest-2026-10-24"`)
- [ ] **Step 2: Run** `swift test --filter NotificationPlannerTests` — Expected: FAIL.
- [ ] **Step 3: Implement.** Digest'i bugünden 14 gün ileriye üret (uygulama her açılışta ve her değişiklikte yeniden planlayacağı için yeterli); sonuçları `fireDate`'e göre sırala, ilk 60'ı döndür.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -am "feat: bildirim planlayıcı"`

### Task 4: Saklama (TodoStore)

**Files:**
- Create: `TodoCore/Sources/TodoCore/TodoStore.swift`
- Test: `TodoCore/Tests/TodoCoreTests/TodoStoreTests.swift`

**Interfaces:**
- Consumes: `TodoItem`, `EntryParser`/`ParsedEntry` (Task 2).
- Produces:
  - `@MainActor public final class TodoStore { public init(inMemory: Bool = false) throws; public var container: ModelContainer; public func add(_ entry: ParsedEntry) -> TodoItem?; public func markDone(_ item: TodoItem, now: Date); public func reopen(_ item: TodoItem); public func delete(_ item: TodoItem); public func openItems() -> [TodoItem]; public func archivedItems() -> [TodoItem]; public func knownPeople() -> [String] }`
  - `add` boş `action` ise `nil` döner ve kaydetmez. `archivedItems` `doneAt` azalan sırada. `knownPeople` benzersiz, boş olmayan kişi adları (artan kullanım sırasıyla azalan).

- [ ] **Step 1: Write the failing tests** (in-memory): `addStoresItem`, `addRejectsEmptyAction`, `markDoneMovesToArchive`, `reopenReturnsToOpen`, `knownPeopleUniqueAndMostUsedFirst`, `deleteRemoves`.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** SwiftData `ModelContext` üstünde; kalıcı mod `~/Library/Application Support/MenuBarTodo/` altına yazar.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Commit** — `git commit -am "feat: TodoStore"`

### Task 5: Mac uygulaması iskeleti ve menü bar paneli

**Files:**
- Create: `project.yml` (XcodeGen: hedef `MenuBarTodo`, macOS 26, `LSUIElement = YES`, TodoCore yerel paket bağımlılığı, bildirim yetkisi)
- Create: `MenuBarTodo/MenuBarTodoApp.swift`, `MenuBarTodo/Panel/PanelView.swift`, `MenuBarTodo/Panel/TodoRow.swift`, `MenuBarTodo/Panel/EntryField.swift`

**Interfaces:**
- Consumes: `TodoStore`, `EntryParser`, `sortedOpenItems`, `Bucket` (Task 1-4).
- Produces: `MenuBarTodoApp` (`MenuBarExtra` + `.menuBarExtraStyle(.window)`), `PanelView` (spec ekran 1), `EntryField` (ekran 2: yazarken `EntryParser.parse` sonucuna göre kişi/iş/tarih etiketleri; Return ile ekler; etikete dokununca düzeltme), `TodoRow(item:onDone:)`.

- [ ] **Step 1:** `brew install xcodegen` (kullanıcıya sor, bu bir indirme), `project.yml` yaz, `xcodegen generate`.
- [ ] **Step 2:** `MenuBarTodoApp` ve `PanelView`'i yaz: gruplar `sortedOpenItems` ile, başlıklar "Gecikmiş / Bugün / Bu hafta / Daha sonra", alt çubuk "Arşiv / Ayarlar". Cam görünüm ve renk kuralları Global Constraints'teki gibi.
- [ ] **Step 3:** `EntryField` ve `TodoRow`: daire dokununca `markDone`; gecikmiş tarih `.red`, diğer tarihler `.secondary`; kişi `.semibold`.
- [ ] **Step 4: Build** — `xcodebuild -project MenuBarTodo.xcodeproj -scheme MenuBarTodo -destination 'platform=macOS' build` — Expected: `** BUILD SUCCEEDED **`.
- [ ] **Step 5: Elle doğrula:** uygulamayı çalıştır; menü bar ikonu çıkar, "Cuma'ya kadar X müşterisine teklif at" yazınca etiketler (X · Teklif at · Cum) görünür, Return ile liste "Bu hafta"da gösterir, daireye basınca listeden kalkar. Ekran görüntüsü al.
- [ ] **Step 6: Commit** — `git add -A && git commit -m "feat: Mac menü bar paneli"`

### Task 6: Arşiv ve ayarlar ekranları

**Files:**
- Create: `MenuBarTodo/Panel/ArchiveView.swift`, `MenuBarTodo/Settings/SettingsView.swift`, `MenuBarTodo/Settings/SettingsStore.swift`

**Interfaces:**
- Consumes: `TodoStore.archivedItems/reopen`, `NotificationSettings` (Task 3-4).
- Produces: `ArchiveView` (sade, yoğun tek satırlık liste, arama kutusu, satıra dokununca `reopen`); `SettingsStore` (`@Observable`, `NotificationSettings`'i `UserDefaults`'a JSON olarak yazar/okur, `var settings: NotificationSettings`); `SettingsView` (spec ekran 6, Apple Takvim anahtarları şimdilik yok).

- [ ] **Step 1:** `SettingsStore`'u yaz; `UserDefaults(suiteName:)` enjekte edilebilir. Birim testi: `TodoCore` dışında olduğu için `MenuBarTodoTests` hedefini `project.yml`'a ekle; test: varsayılan değer 20:00/10:30/12:00/3 döner, kaydet-oku turu aynı değeri verir.
- [ ] **Step 2: Run** `xcodebuild … test` — Expected: PASS.
- [ ] **Step 3:** `ArchiveView` ve `SettingsView`'i yaz; panelin alt çubuğundan açılır.
- [ ] **Step 4: Elle doğrula:** bir işi yapıldı yap → Arşiv'de görünür, dokununca ana listeye döner; ayarda akşam saatini değiştir → uygulamayı kapat-aç, değer korunur.
- [ ] **Step 5: Commit** — `git add -A && git commit -m "feat: arşiv ve ayarlar"`

### Task 7: Bildirimleri bağlama

**Files:**
- Create: `MenuBarTodo/Notifications/NotificationScheduler.swift`
- Modify: `MenuBarTodo/MenuBarTodoApp.swift`

**Interfaces:**
- Consumes: `planNotifications`, `PlannedNotification`, `NotificationSettings`, `TodoStore.openItems`.
- Produces: `@MainActor final class NotificationScheduler { init(center: UNUserNotificationCenter = .current()); func requestAuthorization() async -> Bool; func reschedule(items: [TodoItem], settings: NotificationSettings, now: Date) async }` — mevcut bekleyen bildirimleri siler, `planNotifications` çıktısını `UNCalendarNotificationTrigger` ile ekler.

- [ ] **Step 1: Write the failing test** (`MenuBarTodoTests`): sahte bir `UNUserNotificationCenter` yerine `NotificationCenterProtocol` (`add(_:)`, `removeAllPending()`) enjekte et; `rescheduleReplacesPending`: iki kez çağrılınca ikinci çağrıda önce hepsi silinir, sonra planın sayısı kadar eklenir.
- [ ] **Step 2: Run** — Expected: FAIL.
- [ ] **Step 3: Implement** ve `MenuBarTodoApp`'te: ilk açılışta yetki iste; iş eklendiğinde/yapıldığında/ayar değiştiğinde ve uygulama açılışında `reschedule` çağır.
- [ ] **Step 4: Run** — Expected: PASS.
- [ ] **Step 5: Elle doğrula:** akşam saatini 2 dakika sonrasına ayarla, yarın teslimli bir iş ekle; bildirim gelir, başlık `"Yarına 1 gün kaldı"` yerine `"1 gün kaldı"` biçiminde. Gelen bildirim ekran görüntüsünü al.
- [ ] **Step 6: Commit** — `git add -A && git commit -m "feat: yerel bildirimler"`

---

## Self-review notu

- Spec kapsamı: bu plana ait maddeler (cümle ayrıştırma, bucket'lı liste, tarihsiz işlerin kalması, arşiv, bildirimler ve ayarları, Mac paneli, tasarım dili) görevlere dağıtıldı. Takvim (Apple Takvim, takvim penceresi), iPhone/iCloud, abonelik ve yayın rehberi bilinçli olarak sonraki planlarda.
- Kararlarım (onaylanmadı): gecikmiş işler 12:00 özetine girer; "Bu hafta" = yarından 7 gün; XcodeGen kullanımı; macOS 26 alt sınırı; arşivde arama kutusu.
- Ön koşul (kullanıcı yapacak): `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` ve Xcode lisansı için `sudo xcodebuild -license accept`. Şu an aktif araç seti yalnızca Command Line Tools, Task 5'teki `xcodebuild` bu olmadan çalışmaz; Task 1-4 (`swift test`) çalışır.
