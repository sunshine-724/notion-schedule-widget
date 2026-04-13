import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), items: [
            ScheduleItem(startTime: Date(), endTime: Date().addingTimeInterval(3600), title: "MTG")
        ], pageURL: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let schedule = SharedStorage.shared.loadDailySchedule()
        let items = getActiveItems(items: schedule?.items ?? [], at: Date())
        let entry = SimpleEntry(date: Date(), items: items, pageURL: schedule?.notionPageURL)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        guard let schedule = SharedStorage.shared.loadDailySchedule() else {
            // データが無い場合は現在のエントリのみ（次のユーザアクションを待つ）
            let entry = SimpleEntry(date: currentDate, items: [], pageURL: nil)
            completion(Timeline(entries: [entry], policy: .never))
            return
        }

        var entries: [SimpleEntry] = []
        
        // タイムラインを更新すべき時刻（現在、および各予定の開始・終了時刻）
        var updateDates: Set<Date> = [currentDate]
        for item in schedule.items {
            if item.startTime > currentDate { updateDates.insert(item.startTime) }
            if item.endTime > currentDate { updateDates.insert(item.endTime) }
        }
        
        // 日付順にソートしてそれぞれのエントリを作成
        let sortedDates = updateDates.sorted()
        for date in sortedDates {
            let activeItems = getActiveItems(items: schedule.items, at: date)
            let entry = SimpleEntry(date: date, items: activeItems, pageURL: schedule.notionPageURL)
            entries.append(entry)
        }
        
        // すべての予定が終わった後は、真夜中か次の更新まで待つ（明日の分はアプリが開かれたときか適当に更新）
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    // 特定の時刻における「進行中かこれからの予定」を多めに抽出してViewに渡す
    private func getActiveItems(items: [ScheduleItem], at date: Date) -> [ScheduleItem] {
        let validItems = items.filter { $0.endTime > date }
        return Array(validItems.prefix(10))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [ScheduleItem]
    let pageURL: String?
}

struct NotionScheduleWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var displayCount: Int {
        switch family {
        case .systemSmall: return 2
        case .systemMedium: return 3
        case .systemLarge: return 6
        case .systemExtraLarge: return 10
        default: return 2
        }
    }

    var displayedItems: [ScheduleItem] {
        Array(entry.items.prefix(displayCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日のスケジュール")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.bold)
            
            if displayedItems.isEmpty {
                Spacer()
                Text("予定なし")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(displayedItems) { item in
                    ScheduleRow(item: item, currentDate: entry.date)
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
        // URLが保存されていて且つnotionアプリ起動が要求されているので notion:// スキームへ変換
        .widgetURL(getNotionURL())
    }
    
    private func getNotionURL() -> URL? {
        guard let pageURL = entry.pageURL else { return nil }
        // https://www.notion.so/... -> notion://www.notion.so/... に変換
        if let httpsURL = URL(string: pageURL),
           var components = URLComponents(url: httpsURL, resolvingAgainstBaseURL: false) {
            components.scheme = "notion"
            return components.url
        }
        return URL(string: pageURL)
    }
}

struct ScheduleRow: View {
    let item: ScheduleItem
    let currentDate: Date
    
    var body: some View {
        HStack(alignment: .top) {
            // 左側のインジケーター（進行中の場合は色をつけるなど）
            Rectangle()
                .fill(item.isOngoing(at: currentDate) ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(formatTime(item.startTime)) - \(formatTime(item.endTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

@main
struct NotionScheduleWidget: Widget {
    let kind: String = "NotionScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            // For iOS 17 Widget Backgrounds
            if #available(iOS 17.0, *) {
                NotionScheduleWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                NotionScheduleWidgetEntryView(entry: entry)
                    .background()
            }
        }
        .configurationDisplayName("Notion Schedule")
        .description("Shows your today's plan from Notion.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}
