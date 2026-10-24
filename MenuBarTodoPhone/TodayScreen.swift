import SwiftUI
import SwiftData
import TodoCore

struct TodayScreen: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [TodoItem]
    @State private var editing: TodoItem?
    @State private var focusing = false

    var body: some View {
        let now = Date()
        let visible = items.filter { isVisible($0, horizon: model.settingsStore.horizon, now: now, calendar: model.calendar) }
        let groups = sortedOpenItems(visible, now: now, calendar: model.calendar)
        NavigationStack {
            List {
                ForEach(groups, id: \.0) { bucket, rows in
                    Section(bucketTitle(bucket)) {
                        ForEach(rows) { item in
                            PhoneRow(item: item, now: now, calendar: model.calendar, tint: model.color(for: item), onDone: { model.markDone(item) }, onEdit: { editing = item })
                                .swipeActions(edge: .trailing) {
                                    Button("Yapıldı", systemImage: "checkmark") { model.markDone(item) }.tint(.green)
                                }
                        }
                    }
                }
            }
            .overlay {
                if groups.isEmpty {
                    ContentUnavailableView("Açık iş yok", systemImage: "checkmark.circle", description: Text("Aşağıdan yeni iş yaz."))
                }
            }
            .navigationTitle("İşler")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { focusing = true } label: { Image(systemName: "scope") }.accessibilityLabel("Şimdi sadece bu")
                }
            }
            .fullScreenCover(isPresented: $focusing) {
                NavigationStack {
                    FocusCard(items: groups.flatMap(\.1), compact: false)
                        .padding(24)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .navigationTitle("Odak")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Kapat") { focusing = false } } }
                }
            }
            .safeAreaInset(edge: .bottom) { PhoneEntryField() }
            .sheet(item: $editing) { EditSheet(item: $0) }
        }
    }
}

struct PhoneRow: View {
    let item: TodoItem
    let now: Date
    let calendar: Calendar
    var tint: Color? = nil
    let onDone: () -> Void
    let onEdit: () -> Void

    var body: some View {
        let due = DueLabel(item: item, now: now, calendar: calendar)
        HStack(spacing: 12) {
            Button(action: onDone) {
                Image(systemName: "circle").font(.title3).foregroundStyle(tint ?? Color.secondary)
            }
            .buttonStyle(.plain)
            HStack {
                itemLabel(item).frame(maxWidth: .infinity, alignment: .leading)
                if let progress = checklistProgress(item) { Text(progress).font(.subheadline).foregroundStyle(.tertiary) }
                if item.repeatRule != nil { Image(systemName: "repeat").font(.caption2).foregroundStyle(.tertiary) }
                Text(due.text).font(.subheadline).foregroundStyle(due.isOverdue ? Color.red : Color.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onEdit)
        }
    }
}

struct PhoneEntryField: View {
    @Environment(AppModel.self) private var model
    @State private var text = ""

    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !trimmed.isEmpty { chips }
            HStack {
                TextField("Yeni iş yaz…", text: $text)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .onSubmit(submit)
                if !trimmed.isEmpty {
                    Button("Ekle", action: submit).fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .glassEffect(.regular, in: .capsule)
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
    }

    private var chips: some View {
        let e = model.parser.parse(trimmed, now: Date())
        return HStack(spacing: 6) {
            if let c = model.settingsStore.category(e.categoryID) {
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: c.colorHex)).frame(width: 7, height: 7)
                    Text(c.name)
                }
                .font(.footnote)
                .padding(.horizontal, 10).padding(.vertical, 3)
                .glassEffect(.regular, in: .capsule)
            }
            if let p = e.person { chip(p) }
            if !e.action.isEmpty { chip(e.action.prefix(1).uppercased() + e.action.dropFirst()) }
            if let d = e.dueDate {
                chip(d.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(appLocale)))
            } else if !e.action.isEmpty {
                hint("Tarih yok · Bugün'de bekler")
            }
        }
        .padding(.horizontal, 6)
    }

    private func hint(_ key: LocalizedStringKey) -> some View {
        Text(key).font(.footnote)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .glassEffect(.regular, in: .capsule)
    }

    private func chip(_ s: String) -> some View {
        Text(s).font(.footnote)
            .padding(.horizontal, 10).padding(.vertical, 3)
            .glassEffect(.regular, in: .capsule)
    }

    private func submit() {
        guard !trimmed.isEmpty else { return }
        model.add(trimmed)
        text = ""
    }
}
