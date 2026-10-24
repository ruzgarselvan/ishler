import SwiftUI
import TodoCore

struct EntryField: View {
    @Environment(AppModel.self) private var model
    var onAdded: (() -> Void)? = nil
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextField("Yeni iş yaz…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 9))
                .focused($focused)
                .onSubmit(submit)
            if !trimmed.isEmpty { chips }
        }
        .onAppear { focused = true }
    }

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var chips: some View {
        let e = model.parser.parse(trimmed, now: Date())
        return HStack(spacing: 6) {
            if let c = model.settingsStore.category(e.categoryID) {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: c.colorHex)).frame(width: 6, height: 6)
                    Text(c.name)
                }
                .font(.system(size: 11))
                .padding(.horizontal, 8).padding(.vertical, 1)
                .background(Color(hex: c.colorHex).opacity(0.18), in: Capsule())
            }
            if let p = e.person { chip(p) }
            if !e.action.isEmpty { chip(e.action.prefix(1).uppercased() + e.action.dropFirst()) }
            if let d = e.dueDate {
                chip(d.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "tr_TR"))))
            } else if !e.action.isEmpty {
                chip("Tarih yok · Bugün'de bekler")
            }
        }
        .padding(.horizontal, 2)
    }

    private func chip(_ s: String) -> some View {
        Text(s).font(.system(size: 11))
            .padding(.horizontal, 8).padding(.vertical, 1)
            .background(.quaternary, in: Capsule())
    }

    private func submit() {
        guard !trimmed.isEmpty else { return }
        model.add(trimmed)
        text = ""
        onAdded?()
    }
}
