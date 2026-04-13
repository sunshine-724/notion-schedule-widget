import Foundation

struct SharedStorage {
    static let shared = SharedStorage()
    // App Group Identifier
    private let suitName = "group.com.nakagawakazuki.NotionScheduleWidget"
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: suitName)
    }
    
    private let key = "daily_schedule"
    
    func saveDailySchedule(_ schedule: DailySchedule) {
        if let encoded = try? JSONEncoder().encode(schedule) {
            userDefaults?.set(encoded, forKey: key)
        }
    }
    
    func loadDailySchedule() -> DailySchedule? {
        if let data = userDefaults?.data(forKey: key),
           let decoded = try? JSONDecoder().decode(DailySchedule.self, from: data) {
            return decoded
        }
        return nil
    }
    
    func clearSchedule() {
        userDefaults?.removeObject(forKey: key)
    }
}
