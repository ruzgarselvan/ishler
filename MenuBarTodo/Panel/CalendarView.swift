import SwiftUI
import SwiftData
import EventKit
import TodoCore

struct CalendarView: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [TodoItem]
    @State private var events = EventsProvider()
    @State private var month = Date()
    @State private var selected = Date()
    let onBack: () -> Void
    let onEdit: (TodoItem) -> Void

    private var cal: Calendar { model.calendar }
    private let tr = appLocale

    var body: some View {
        let open = items.filter { !$0.isDone && $0.dueDate != nil }
        let dayItems = open.filter { cal.isDate($0.dueDate!, inSameDayAs: selected) }
        let dayEvents = (events.byDay[cal.startOfDay(for: selected)] ?? []).sorted { $0.startDate < $1.startDate }
        VStack(alignment: .leading, spacing: 8) {
            PanelHeader(title: "Takvim", onBack: onBack)
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year().locale(tr)))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                Button("Bugün") { month = Date(); selected = Date() }
                Button { shift(1) } label: { Image(systemName: "chevron.right") }
            }
            .buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(Color.accentColor)

            grid(open)

            Text(selected.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(tr)))
                .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary).padding(.top, 2)

            if dayItems.isEmpty && dayEvents.isEmpty {
                Text("Bu gün için bir şey yok").font(.system(size: 12)).foregroundStyle(.tertiary)
            } else {
                FittedScroll(maxHeight: 200) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(dayItems) { item in
                            TodoRow(item: item, now: Date(), calendar: cal, tint: model.color(for: item),
                                    onDone: { model.markDone(item) }, onEdit: { onEdit(item) })
                        }
                        ForEach(dayEvents, id: \.eventIdentifier) { e in
                            HStack(spacing: 9) {
                                Circle().fill(Color(cgColor: e.calendar.cgColor)).frame(width: 7, height: 7)
                                Text(e.title ?? "").lineLimit(1).foregroundStyle(.secondary)
                                Spacer()
                                Text(e.isAllDay ? "Tüm gün" : e.startDate.formatted(.dateTime.hour().minute().locale(tr)))
                                    .foregroundStyle(.tertiary)
                            }
                            .font(.system(size: 12)).padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .background(SwipeMonitor { shift($0) })
        .task(id: month) { await events.load(month: month, calendar: cal) }
    }

    private func shift(_ delta: Int) { month = cal.date(byAdding: .month, value: delta, to: month) ?? month }

    private func grid(_ open: [TodoItem]) -> some View {
        let days = monthDays(of: month, calendar: cal)
        return VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(Array(weekdayInitials(cal).enumerated()), id: \.offset) { _, initial in
                    Text(initial).font(.system(size: 10)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 2) {
                ForEach(days.indices, id: \.self) { i in
                    if let day = days[i] { cell(day, open: open) } else { Color.clear.frame(height: 32) }
                }
            }
        }
    }

    private func cell(_ day: Date, open: [TodoItem]) -> some View {
        let isToday = cal.isDateInToday(day)
        let isSelected = cal.isDate(day, inSameDayAs: selected)
        let hasItem = open.contains { cal.isDate($0.dueDate!, inSameDayAs: day) }
        let hasEvent = !(events.byDay[cal.startOfDay(for: day)] ?? []).isEmpty
        return Button { selected = day } label: {
            VStack(spacing: 1) {
                Text("\(cal.component(.day, from: day))")
                    .font(.system(size: 12, weight: isToday || isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
                    .frame(width: 22, height: 22)
                    .background(isSelected ? Color.accentColor : Color.clear, in: Circle())
                HStack(spacing: 2) {
                    Circle().fill(hasItem ? Color.accentColor : .clear).frame(width: 4, height: 4)
                    Circle().fill(hasEvent ? Color.secondary.opacity(0.6) : .clear).frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
