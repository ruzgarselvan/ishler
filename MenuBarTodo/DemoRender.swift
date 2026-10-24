#if DEBUG
import AppKit
import SwiftData
import SwiftUI
import TodoCore

/// Debug aid for website screenshots: a static look-alike of the menu bar panel (same rows, no scrolling or text field
/// state), rendered straight to a PNG with ImageRenderer so no Screen Recording permission is needed.
@MainActor
enum DemoRender {
    static func panel(model: AppModel, dark: Bool, to path: String) {
        let now = Date()
        let groups = sortedOpenItems(model.store.openItems(), now: now, calendar: model.calendar)
        let view = VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(LocalizedStringKey("Yeni iş yaz…")).foregroundStyle(.secondary).font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
            ForEach(groups, id: \.0) { bucket, rows in
                Text(bucketTitle(bucket)).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    .padding(.top, 8).padding(.bottom, 1)
                ForEach(rows.prefix(4)) { item in
                    TodoRow(item: item, now: now, calendar: model.calendar, tint: model.color(for: item), onDone: {}, onEdit: {})
                        .environment(model)
                }
            }
            HStack(spacing: 12) {
                Text(LocalizedStringKey("\(model.store.openItems().count) açık iş"))
                Spacer()
                Image(systemName: "scope"); Image(systemName: "calendar"); Image(systemName: "archivebox")
                Image(systemName: "gearshape"); Image(systemName: "power")
            }
            .font(.system(size: 11)).foregroundStyle(.secondary).padding(.top, 8)
        }
        .padding(14)
        .frame(width: 320)
        .background(dark ? Color(white: 0.16) : Color(white: 0.97), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.primary.opacity(0.12)))
        .padding(30)
        .environment(\.colorScheme, dark ? .dark : .light)
        .environment(\.locale, Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en"))

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        if let image = renderer.nsImage, let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) {
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
        }
    }
}
#endif
