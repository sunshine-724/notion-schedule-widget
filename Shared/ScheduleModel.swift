import Foundation

struct ScheduleItem: Codable, Identifiable {
    var id: String { title + startTime.description }
    let startTime: Date
    let endTime: Date
    let title: String
    
    // 現在時刻との比較（進行中かどうか）
    func isOngoing(at date: Date = Date()) -> Bool {
        return date >= startTime && date < endTime
    }
    
    // まだ終わっていないか（これからか）
    func isUpcomingOrOngoing(at date: Date = Date()) -> Bool {
        return date < endTime
    }
}

// Widgetへ渡すすべての予定群
struct DailySchedule: Codable {
    let dateString: String // YYYY-MM-DD
    let items: [ScheduleItem]
    let notionPageURL: String?
}
