import SwiftUI
import TodoCore

/// Templates: typing a name at the start of a note adds its steps as the item's checklist.
struct TemplateEditor: View {
    @Bindable var store: SettingsStore
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            ForEach($store.templates) { $template in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TextField("Şablon adı", text: $template.name).textFieldStyle(.plain).fontWeight(.semibold)
                        Button { store.templates.removeAll { $0.id == template.id } } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    TextField("Adımlar, virgülle ayır", text: Binding(
                        get: { template.steps.joined(separator: ", ") },
                        set: { template.steps = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                    ), axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: compact ? 11 : 14))
                }
            }
            Button { store.templates.append(ChecklistTemplate(name: "Yeni şablon", steps: [])) } label: {
                Label("Şablon ekle", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.plain).foregroundStyle(Color.accentColor)
            Text("Notun başına şablon adını yaz: \"çekim sonrası Deniz Cuma\"")
                .font(.system(size: compact ? 11 : 13)).foregroundStyle(.secondary)
        }
        .font(.system(size: compact ? 12 : 17))
    }
}
