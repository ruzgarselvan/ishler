import SwiftUI
import TodoCore

/// "Düzenli işler": fixed tasks with an optional schedule ("every month on the 15th") that put themselves on the list.
/// Typing a routine's name at the start of a note also adds its steps.
struct RoutineEditor: View {
    @Bindable var store: SettingsStore
    @Environment(AppModel.self) private var model
    var compact = false

    private enum Kind: String { case none, daily, weekly, monthly }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 16) {
            ForEach(store.templates) { current in
                let routineBinding = binding(for: current.id)
                let routine = current
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TextField("İş adı", text: routineBinding.name).textFieldStyle(.plain).fontWeight(.semibold)
                        Button { store.templates.removeAll { $0.id == routine.id } } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    Picker("Tekrar", selection: kind(for: routineBinding)) {
                        Text("Yok").tag(Kind.none)
                        Text("Her gün").tag(Kind.daily)
                        Text("Her hafta").tag(Kind.weekly)
                        Text("Her ay").tag(Kind.monthly)
                    }
                    if routine.schedule?.hasPrefix("weekly") == true {
                        Picker("Haftanın günü", selection: weekday(for: routineBinding)) {
                            ForEach(weekdayOrder, id: \.self) { Text(model.calendar.weekdaySymbols[$0 - 1]).tag($0) }
                        }
                    }
                    if routine.schedule?.hasPrefix("monthly") == true {
                        Stepper("Ayın günü: \(dayOfMonth(routine.schedule))", value: dayBinding(for: routineBinding), in: 1...31)
                    }
                    TextField("Adımlar, virgülle ayır", text: Binding(
                        get: { routine.steps.joined(separator: ", ") },
                        set: { routineBinding.wrappedValue.steps = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                    ), axis: .vertical)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: compact ? 11 : 14))
                    if !store.categories.isEmpty {
                        CategoryMenu(categories: store.categories, selection: routineBinding.categoryID)
                    }
                }
            }
            Button { store.templates.append(ChecklistTemplate(name: String(localized: "Yeni düzenli iş"), steps: [])) } label: {
                Label("Düzenli iş ekle", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.plain).foregroundStyle(Color.accentColor)
            Text("Fatura kes gibi sabit işleri zamanlayabilirsin: zamanı gelince kendiliğinden listene düşer. Adını notun başına yazarak adımlarını da ekleyebilirsin.")
                .font(.system(size: compact ? 11 : 13)).foregroundStyle(.secondary)
        }
        .font(.system(size: compact ? 12 : 17))
    }

    /// Looks the routine up by id on every read and write, so deleting one never leaves a binding pointing past the end of the array.
    private func binding(for id: UUID) -> Binding<ChecklistTemplate> {
        Binding(
            get: { store.templates.first { $0.id == id } ?? ChecklistTemplate(id: id, name: "", steps: []) },
            set: { new in if let i = store.templates.firstIndex(where: { $0.id == id }) { store.templates[i] = new } }
        )
    }

    /// Weekday numbers in the calendar's week order.
    private var weekdayOrder: [Int] { (0..<7).map { (model.calendar.firstWeekday - 1 + $0) % 7 + 1 } }

    private func dayOfMonth(_ schedule: String?) -> Int {
        schedule.flatMap { $0.split(separator: ":").dropFirst().first }.flatMap { Int($0) } ?? 1
    }

    private func kind(for routine: Binding<ChecklistTemplate>) -> Binding<Kind> {
        Binding(
            get: {
                switch routine.wrappedValue.schedule?.split(separator: ":").first {
                case "daily": .daily
                case "weekly": .weekly
                case "monthly": .monthly
                default: .none
                }
            },
            set: {
                switch $0 {
                case .none: routine.wrappedValue.schedule = nil
                case .daily: routine.wrappedValue.schedule = "daily"
                case .weekly: routine.wrappedValue.schedule = "weekly:2"
                case .monthly: routine.wrappedValue.schedule = "monthly:1"
                }
            }
        )
    }

    private func weekday(for routine: Binding<ChecklistTemplate>) -> Binding<Int> {
        Binding(
            get: { dayOfMonth(routine.wrappedValue.schedule) },
            set: { routine.wrappedValue.schedule = "weekly:\($0)" }
        )
    }

    private func dayBinding(for routine: Binding<ChecklistTemplate>) -> Binding<Int> {
        Binding(
            get: { dayOfMonth(routine.wrappedValue.schedule) },
            set: { routine.wrappedValue.schedule = "monthly:\($0)" }
        )
    }
}
