import SwiftUI
import SwiftData
import EventKit
import TodoCore

struct CalendarScreen: View {
    @Environment(AppModel.self) private var model
    @Query private var items: [TodoItem]
    @State private var events = EventsProvider()
    @State private var month = Date()
    @State private var selected = Date()
    @State private var editing: TodoItem?

    private var cal: Calendar { model.calendar }
    private let tr = Locale(identifier: "tr_TR")
    private let weekdayInitials = ["P", "S", "Ç", "P", "C", "C", "P"]

    var body: some View {
        let open = items.filter { !$0.isDone && $0.dueDate != nil }
        let dayItems = open.filter { cal.isDate($0.dueDate!, inSameDayAs: selected) }
        let dayEvents = (events.byDay[cal.startOfDay(for: selected)] ?? []).sorted { $0.startDate < $1.startDate }
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    monthHeader
                    grid(open)
                        .padding(12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 22))

                    Text(selected.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(tr)))
                        .font(.headline).padding(.horizontal, 4)

                    if dayItems.isEmpty && dayEvents.isEmpty {
                        Text("Bu gün için bir şey yok").foregroundStyle(.secondary).padding(.horizontal, 4)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(dayItems) { item in
                                PhoneRow(item: item, now: Date(), calendar: cal,
                                         onDone: { model.markDone(item) }, onEdit: { editing = item })
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                            }
                            ForEach(dayEvents, id: \.eventIdentifier) { e in
                                HStack(spacing: 12) {
                                    Circle().fill(Color(cgColor: e.calendar.cgColor)).frame(width: 8, height: 8)
                                    Text(e.title ?? "").foregroundStyle(.secondary).lineLimit(1)
                                    Spacer()
                                    Text(e.isAllDay ? "Tüm gün" : e.startDate.formatted(.dateTime.hour().minute().locale(tr)))
                                        .font(.subheadline).foregroundStyle(.tertiary)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                            }
                        }
                        .background(.background, in: RoundedRectangle(cornerRadius: 22))
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Takvim")
            .sheet(item: $editing) { EditSheet(item: $0) }
            .task(id: month) { await events.load(month: month, calendar: cal) }
        }
    }

    private var monthHeader: some View {
        HStack {
            Text(month.formatted(.dateTime.month(.wide).year().locale(tr))).font(.title3.weight(.semibold))
            Spacer()
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
            Button { month = Date(); selected = Date() } label: { Text("Bugün").font(.subheadline) }
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal, 4)
    }

    private func shift(_ delta: Int) {
        month = cal.date(byAdding: .month, value: delta, to: month) ?? month
    }

    private func grid(_ open: [TodoItem]) -> some View {
        let days = monthDays()
        return VStack(spacing: 6) {
            HStack {
                ForEach(weekdayInitials.indices, id: \.self) { i in
                    Text(weekdayInitials[i]).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days.indices, id: \.self) { i in
                    if let day = days[i] { dayCell(day, open: open) } else { Color.clear.frame(height: 44) }
                }
            }
        }
    }

    private func dayCell(_ day: Date, open: [TodoItem]) -> some View {
        let isToday = cal.isDateInToday(day)
        let isSelected = cal.isDate(day, inSameDayAs: selected)
        let hasItem = open.contains { cal.isDate($0.dueDate!, inSameDayAs: day) }
        let hasEvent = !(events.byDay[cal.startOfDay(for: day)] ?? []).isEmpty
        return Button { selected = day } label: {
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: day))")
                    .font(.system(size: 16, weight: isToday || isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : (isToday ? Color.accentColor : Color.primary))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.accentColor : Color.clear, in: Circle())
                HStack(spacing: 3) {
                    Circle().fill(hasItem ? Color.accentColor : .clear).frame(width: 5, height: 5)
                    Circle().fill(hasEvent ? Color.secondary.opacity(0.6) : .clear).frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    /// Days of `month` padded with leading nils so the first day lands on its weekday column.
    private func monthDays() -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        let first = interval.start
        let offset = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        let count = cal.range(of: .day, in: .month, for: first)?.count ?? 30
        return Array(repeating: nil, count: offset) + (0..<count).map { cal.date(byAdding: .day, value: $0, to: first) }
    }
}
