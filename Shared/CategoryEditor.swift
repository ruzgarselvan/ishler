import SwiftUI
import TodoCore

private let palette = ["#FF9500", "#34C759", "#007AFF", "#AF52DE", "#FF2D55", "#30B0C7", "#FFCC00"]
private let shortcutCandidates = ["x", "1", "2", "3", "4", "5"]

/// Category list plus the shortcut-spelling toggles; shared by the Mac and iPhone settings.
struct CategoryEditor: View {
    @Bindable var store: SettingsStore
    var compact = false
    @State private var expanded: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            ForEach(store.categories) { current in
                let categoryBinding = binding(for: current.id)
                let category = current
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Button {
                            expanded = expanded == category.id ? nil : category.id
                        } label: {
                            Circle().fill(Color(hex: category.colorHex)).frame(width: 18, height: 18)
                                .overlay(Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .help("Renk seç")
                        TextField("Ad", text: categoryBinding.name).textFieldStyle(.plain)
                        TextField("x", text: categoryBinding.shortcut)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .frame(width: 34)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                            .onChange(of: category.shortcut) { categoryBinding.wrappedValue.shortcut = String(categoryBinding.wrappedValue.shortcut.prefix(3)) }
                        Button { categoryBinding.wrappedValue.remind.toggle() } label: {
                            Image(systemName: category.remind ? "bell.fill" : "bell.slash")
                                .foregroundStyle(category.remind ? Color.accentColor : Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(category.remind ? LocalizedStringKey("Hatırlatma açık") : LocalizedStringKey("Hatırlatma kapalı"))
                        Button {
                            store.categories.removeAll { $0.id == category.id }
                        } label: { Image(systemName: "minus.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.plain)
                    }
                    if expanded == category.id {
                        HStack(spacing: compact ? 8 : 12) {
                            ForEach(palette, id: \.self) { hex in
                                Button {
                                    categoryBinding.wrappedValue.colorHex = hex
                                    expanded = nil
                                } label: {
                                    Circle().fill(Color(hex: hex)).frame(width: compact ? 20 : 28, height: compact ? 20 : 28)
                                        .overlay {
                                            if category.colorHex.uppercased() == hex {
                                                Image(systemName: "checkmark").font(.system(size: compact ? 9 : 12, weight: .bold)).foregroundStyle(.white)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.leading, 26)
                    }
                }
            }
            Button { addCategory() } label: { Label("Kategori ekle", systemImage: "plus.circle.fill") }
                .buttonStyle(.plain).foregroundStyle(Color.accentColor)

            if !store.categories.isEmpty {
                Text("Zil açık olan kategorilerin işleri için teslim hatırlatması gelir.")
                    .font(.system(size: compact ? 11 : 13)).foregroundStyle(.secondary)
                Text("Notun sonuna kısayolu yaz: \"logo teslimi x\" ya da, Parantez açıksa, \"logo teslimi (x)\". Kısayol harf ya da rakam olabilir.")
                    .font(.system(size: compact ? 11 : 13)).foregroundStyle(.secondary)
                Toggle("Parantez", isOn: $store.shortcuts.parentheses)
            }
        }
        .font(.system(size: compact ? 12 : 17))
    }

    /// Looks the category up by id on every read and write, so deleting one never leaves a binding pointing past the end of the array.
    private func binding(for id: UUID) -> Binding<TodoCategory> {
        Binding(
            get: { store.categories.first { $0.id == id } ?? TodoCategory(id: id, name: "", shortcut: "", colorHex: "#8E8E93") },
            set: { new in if let i = store.categories.firstIndex(where: { $0.id == id }) { store.categories[i] = new } }
        )
    }

    private func addCategory() {
        let used = Set(store.categories.map { $0.shortcut.lowercased() })
        let shortcut = shortcutCandidates.first { !used.contains($0) } ?? ""
        let color = palette[store.categories.count % palette.count]
        store.categories.append(TodoCategory(name: String(localized: "Kategori"), shortcut: shortcut, colorHex: color))
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
