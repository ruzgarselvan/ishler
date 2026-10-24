import SwiftUI
import TodoCore

private let palette = ["#FF9500", "#34C759", "#007AFF", "#AF52DE", "#FF2D55", "#30B0C7"]
private let shortcutCandidates = ["x", "1", "2", "3", "4", "5"]

/// Category list plus the shortcut-spelling toggles; shared by the Mac and iPhone settings.
struct CategoryEditor: View {
    @Bindable var store: SettingsStore
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            ForEach($store.categories) { $category in
                HStack(spacing: 8) {
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: category.colorHex) },
                        set: { category.colorHex = $0.hexString }
                    ), supportsOpacity: false)
                    .labelsHidden()
                    TextField("Ad", text: $category.name).textFieldStyle(.plain)
                    TextField("x", text: $category.shortcut)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.center)
                        .frame(width: 34)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                        .onChange(of: category.shortcut) { category.shortcut = String(category.shortcut.prefix(3)) }
                    Button {
                        store.categories.removeAll { $0.id == category.id }
                    } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.secondary) }
                    .buttonStyle(.plain)
                }
            }
            Button { addCategory() } label: { Label("Kategori ekle", systemImage: "plus.circle.fill") }
                .buttonStyle(.plain).foregroundStyle(Color.accentColor)

            if !store.categories.isEmpty {
                Text("Notun sonuna kısayolu yaz: \"logo teslimi x\"")
                    .font(.system(size: compact ? 11 : 13)).foregroundStyle(.secondary)
                Toggle("Harf kısayolu (x)", isOn: $store.shortcuts.letters)
                Toggle("Rakam kısayolu (1)", isOn: $store.shortcuts.digits)
                Toggle("Parantezli yazım ((x), (1))", isOn: $store.shortcuts.parentheses)
            }
        }
        .font(.system(size: compact ? 12 : 17))
    }

    private func addCategory() {
        let used = Set(store.categories.map { $0.shortcut.lowercased() })
        let shortcut = shortcutCandidates.first { !used.contains($0) } ?? ""
        let color = palette[store.categories.count % palette.count]
        store.categories.append(TodoCategory(name: "Kategori", shortcut: shortcut, colorHex: color))
    }
}

/// Picker used by the edit screens: "Kategori yok" plus every configured category.
struct CategoryMenu: View {
    let categories: [TodoCategory]
    @Binding var selection: UUID?

    var body: some View {
        Picker("Kategori", selection: $selection) {
            Text("Yok").tag(UUID?.none)
            ForEach(categories) { c in
                Label { Text(c.name) } icon: { Image(systemName: "circle.fill").foregroundStyle(Color(hex: c.colorHex)) }
                    .tag(UUID?.some(c.id))
            }
        }
    }
}
