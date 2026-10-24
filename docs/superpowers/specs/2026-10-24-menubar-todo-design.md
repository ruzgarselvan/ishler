# Menü bar iş takip uygulaması: tasarım

Tarih: 2026-10-24 · Durum: kullanıcı "hadi build edelim" dedi, onay olarak alındı.

## Niyet ve neden

Kullanıcı ADHD'li bir freelancer. Notlar, takvim ve 5-10 ayrı todo listesi arasında işler kayboluyor. Sorun yazmak değil, yazdıktan sonra tekrar bakmak: takvime yazdığını unutuyor, kontrol etmiyor. Çözüm tek bir yer: menü bar'da (Mac) ve telefonda (iPhone) düz cümleyle iş yazılıyor, uygulama cümleyi parçalıyor, tarihleri takvime koyuyor ve zamanı gelince hatırlatıyor.

Örnek: "Cuma'ya kadar X müşterisine teklif at" → kişi: X, iş: teklif at, tarih: Cuma.

Kullanıcı bunu ileride App Store'da satmak istiyor. İlk uygulaması, daha önce hiçbir platformda yayın yapmadı.

## Hedefler

- Cümle yazarak iş ekleme, form yok.
- Tek liste, tarihe göre sıralı: Gecikmiş / Bugün / Bu hafta.
- Tarihsiz işler ("Deniz'i ara, işi sor") "Bugün"de durur ve kullanıcı "yapıldı" diyene kadar orada kalır. Ertesi güne kaymaz, silinmez.
- Kendi takvim görünümü + Apple Takvim'e yazma ve Apple Takvim'den okuma (okunan etkinlikler, örn. çekim günleri, gri görünür).
- Bildirimler: teslim tarihine son 3 gün her akşam, teslim günü sabah, tarihsiz işler için gündüz bir saat. Saatler ayarlardan değişir. Varsayılan tahminler: akşam 20:00, sabah 10:30, tarihsiz işler 12:00.
- "Yapıldı" işleri arşivde saklanır, silinmez, dokununca geri açılır.
- Mac menü bar paneli + iPhone uygulaması, aralarında iCloud senkronu.
- App Store'a yayın: ilk 1 ay ücretsiz deneme, sonra yıllık abonelik (~120 TL, Apple fiyat basamağına göre).

## Hedef olmayanlar

- Sunucu, hesap sistemi, yapay zekâ servisi yok.
- Bildirimleri dikkat çekici/değişken yapma çabası yok (kullanıcı istemedi, sade kalsın).
- Android/web yok.
- Ertesi güne otomatik kaydırma yok.

## Tasarım dili

Apple'ın kendi uygulaması gibi: Liquid Glass / buzlu cam yüzeyler, SF fontu, sistem renkleri. Sarı vurgu ve renkli etiketler yok. Kişi adı sadece kalın yazıyla ayrılır. Tek renkli öğe gecikmiş tarih (kırmızı) ve birincil buton (mavi). Onaylanan taslaklar: `.superpowers/brainstorm/36128-1792829978/content/all-screens-v1.html`.

Ekranlar: Mac için ana panel, yazarken (anlaşılanı gösteren etiketler), iş detayı, arşiv, takvim penceresi, ayarlar. iPhone için liste, yazma ekranı, takvim, arşiv, bildirim. **Arşiv sade olacak:** yoğun, tek satırlık liste, ana arayüzün süsünü taşımaz. Kilit ekranı bildirimi gerçek iOS bildirimi olur, özel çizim yok.

## Cümleyi anlama (sunucusuz, yapay zekâsız)

- Tarih: Apple'ın tarih tanıyıcısı (NSDataDetector) + eksik Türkçe ifadeler için kendi kurallar. İlk iş küçük bir denemeyle Türkçe başarısını ölçmek.
- Kişi: büyük harfli ya da ek alan kelime ("X'e", "Deniz'i"). Daha önce kullanılan kişiler hatırlanır ve öncelikli eşleşir.
- İş: kalan kısım.
- Yanlış anlama: yazarken çıkan etiketlere dokunularak düzeltilir.
- İleride isteğe bağlı olarak Apple Intelligence destekleyen cihazlarda "akıllı mod" eklenebilir; uygulama ona bağımlı olmaz.

## Kısıtlar ve teknik seçimler

Kullanıcı bunları devretti, benim kararım (onaylanmadı, değiştirilebilir):

- Swift + SwiftUI, hem macOS hem iOS, mümkün olduğunca ortak kod.
- Veri: SwiftData + iCloud (CloudKit) senkronu.
- Takvim: EventKit.
- Bildirim: yerel bildirimler (UserNotifications), sunucu gerekmez.
- Abonelik: StoreKit 2, intro offer olarak 1 aylık ücretsiz deneme.
- Dil: arayüz Türkçe.

Kullanıcının cihazları: iPhone 16e, Mac M5 Pro (ikisi de Apple Intelligence destekler, ama kullanılmıyor).

## Abonelik bitince

Deneme/abonelik bitince: işleri görme ve "yapıldı" işaretleme açık, yeni iş ekleme ve bildirimler kapalı. Veri hiçbir zaman kilitlenmez.

## Yayın yardımı (kullanıcı hiç yayınlamadı)

Plan, adım adım yönlendirmeyi içermeli: Apple Developer Program üyeliği, uygulama kimliği ve iCloud/Takvim/Bildirim yetkileri, TestFlight ile test, App Store Connect kaydı, gizlilik politikası ve App Store gizlilik etiketi, abonelik ürünü kurulumu, ekran görüntüleri, inceleme süreci, Small Business Program başvurusu. Sistem takibi (çökme raporu) için Apple'ın kendi araçları (Xcode Organizer, App Store Connect analizleri) kullanılır, ek servis yok. Güncellemeler App Store üzerinden yapılır.

## Başarı ve başarısızlık ölçütü

Kullanıcı başarısızlık ölçütünü şimdiden tarif edemedi ("kullanmaya başlayınca gelir"). Bu yüzden ilk sürüm küçük tutulur ve kullanıcının kendi günlük kullanımıyla öğrenilir.

## Kurucuya bırakılanlar

Proje yapısı, ortak kod organizasyonu, Türkçe cümle ayrıştırıcının ayrıntıları, bildirim zamanlama mantığı, ilk sürümde hangi ekranların önce çıkacağı (öneri: Mac paneli + yazma + liste + yerel bildirim önce; takvim, iCloud, iPhone, abonelik sonra).
