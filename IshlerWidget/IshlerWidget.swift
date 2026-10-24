import SwiftData
import SwiftUI
import TodoCore
import WidgetKit

struct TaskRow: Identifiable {
    let id: UUID
    let text: String
    let due: String
    let overdue: Bool
}

struct TasksEntry: TimelineEntry {
    let date: Date
    let rows: [TaskRow]
    let openCount: Int
}

/// Reads the open tasks straight from the app's store in the shared App Group container (no iCloud, read-only).
struct TasksProvider: TimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(date: .now, rows: [
            TaskRow(id: UUID(), text: "Deniz · ara", due: String(localized: "Bugün"), overdue: false),
            TaskRow(id: UUID(), text: "Fatura kes", due: String(localized: "Yarın"), overdue: false),
        ], openCount: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> Void) { completion(load()) }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(.now.addingTimeInterval(15 * 60))))
    }

    private func load() -> TasksEntry {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TodoStore.appGroupID),
              let container = try? ModelContainer(
                for: Schema([TodoItem.self]),
                configurations: ModelConfiguration(schema: Schema([TodoItem.self]), url: dir.appending(path: "ishler.store"),
                                                   allowsSave: false, cloudKitDatabase: .none))
        else { return TasksEntry(date: .now, rows: [], openCount: 0) }

        let items = (try? ModelContext(container).fetch(FetchDescriptor<TodoItem>())) ?? []
        let ordered = sortedOpenItems(items, now: .now, calendar: calendar).flatMap(\.1)
        let rows = ordered.prefix(5).map { item -> TaskRow in
            let label = item.dueDate.map { dueLabelText(due: $0, now: .now, calendar: calendar) }
            let clock = item.dueMinutes.map { String(format: " %02d:%02d", $0 / 60, $0 % 60) } ?? ""
            return TaskRow(id: item.id,
                           text: item.person.map { "\($0) · \(item.action)" } ?? item.action,
                           due: label.map { $0.text + ($0.isOverdue ? "" : clock) } ?? String(localized: "Bekliyor"),
                           overdue: label?.isOverdue ?? false)
        }
        return TasksEntry(date: .now, rows: Array(rows), openCount: ordered.count)
    }
}

struct TasksWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TasksEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Text(entry.rows.first?.text ?? String(localized: "Açık iş yok"))
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text("\(entry.openCount)").font(.system(size: 22, weight: .semibold, design: .rounded))
                Image(systemName: "checklist").font(.system(size: 10))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                if entry.rows.isEmpty { Text("Açık iş yok") } else {
                    ForEach(entry.rows.prefix(2)) { row in
                        Text(row.text).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        Text(row.due).font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
            }
        default:
            let limit = family == .systemSmall ? 3 : 5
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("İşler").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("\(entry.openCount)").font(.system(size: 13)).foregroundStyle(.secondary)
                }
                if entry.rows.isEmpty {
                    Spacer()
                    Text("Açık iş yok").foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ForEach(entry.rows.prefix(limit)) { row in
                        HStack(spacing: 6) {
                            Text(row.text).font(.system(size: 13)).lineLimit(1)
                            Spacer(minLength: 4)
                            if family != .systemSmall {
                                Text(row.due).font(.system(size: 11)).foregroundStyle(row.overdue ? Color.red : Color.secondary)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

struct TasksWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "IshlerTasks", provider: TasksProvider()) { entry in
            TasksWidgetView(entry: entry).containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("İşler")
        .description("Sıradaki işlerini gösterir.")
        .supportedFamilies(widgetFamilies)
    }

    private var widgetFamilies: [WidgetFamily] {
        #if os(iOS)
        [.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular]
        #else
        [.systemSmall, .systemMedium]
        #endif
    }
}

@main
struct IshlerWidgets: WidgetBundle {
    var body: some Widget { TasksWidget() }
}
