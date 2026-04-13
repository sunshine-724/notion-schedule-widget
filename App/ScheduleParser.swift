import Foundation

struct ScheduleParser {
    static func parseScheduleLines(texts: [String], targetDate: Date = Date()) -> [ScheduleItem] {
        var items: [ScheduleItem] = []
        let calendar = Calendar.current
        
        // 当日の年・月・日を取得しておく（HH:mmからDateを構築するため）
        let year = calendar.component(.year, from: targetDate)
        let month = calendar.component(.month, from: targetDate)
        let day = calendar.component(.day, from: targetDate)
        
        // Regex for "[-]? HH:mm-HH:mm タイトル"
        let pattern = #"^\s*(?:-\s*)?(?:\[[ xX]\]\s*)?(\d{1,2}):(\d{2})\s*(?:-|~|〜)\s*(\d{1,2}):(\d{2})\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        
        var isInsideTargetSection = false
        
        for text in texts {
            // Notionのブロックテキストとして渡ってくることを想定
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // "### Today's Plan" (か、単に "Today's Plan" や "Today’s Plan" 等のHeading)
            if trimmed.lowercased().contains("today's plan") || trimmed.lowercased().contains("today’s plan") {
                isInsideTargetSection = true
                continue
            }
            
            // "---" か "Divider" 相当の文字列で終了とみなす
            if trimmed == "---" {
                if isInsideTargetSection { break } // 終了
            }
            
            guard isInsideTargetSection else { continue }
            
            // 取り消し線や不要な行は無視などしたいが、とりあえずフォーマット判定
            let nsString = trimmed as NSString
            let results = regex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))
            
            guard let match = results.first, match.numberOfRanges == 6 else { continue }
            
            let startHourStr = nsString.substring(with: match.range(at: 1))
            let startMinStr = nsString.substring(with: match.range(at: 2))
            let endHourStr = nsString.substring(with: match.range(at: 3))
            let endMinStr = nsString.substring(with: match.range(at: 4))
            let title = nsString.substring(with: match.range(at: 5))
            
            guard let startH = Int(startHourStr), let startM = Int(startMinStr),
                  let endH = Int(endHourStr), let endM = Int(endMinStr) else { continue }
            
            var startComponents = DateComponents(year: year, month: month, day: day, hour: startH, minute: startM)
            var endComponents = DateComponents(year: year, month: month, day: day, hour: endH, minute: endM)
            
            if let startDate = calendar.date(from: startComponents),
               var endDate = calendar.date(from: endComponents) {
               
                // もし終了時刻が開始時刻より前なら（例: 23:00 - 01:00）、日をまたいでいると解釈
                if endDate < startDate {
                    endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
                }
                
                let item = ScheduleItem(startTime: startDate, endTime: endDate, title: title)
                items.append(item)
            }
        }
        
        // 開始時刻で昇順ソート
        return items.sorted { $0.startTime < $1.startTime }
    }
}
