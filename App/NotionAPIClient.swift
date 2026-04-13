import Foundation

enum NotionAPIError: Error {
    case noToken
    case invalidURL
    case badResponse(Int)
    case pageNotFound
}

struct NotionPageResponse: Decodable {
    let results: [NotionPage]
}

struct NotionPage: Decodable {
    let id: String
    let url: String
}

struct NotionBlockResponse: Decodable {
    let results: [NotionBlock]
}

struct NotionBlock: Decodable {
    let id: String
    let type: String
    // Block content dynamically based on type (paragraph, heading_3, bulleted_list_item, etc.)
    // We can use a custom decoder or just try to decode the common structures.
    // For simplicity, we decode as a catch-all for `rich_text`
    
    // We will parse the raw dictionary
}

class NotionAPIClient {
    static let shared = NotionAPIClient()
    
    private let baseURL = "https://api.notion.com/v1"
    private var token: String? {
        KeychainHelper.standard.readToken()
    }
    
    private func makeRequest(path: String, method: String, body: Data? = nil) throws -> URLRequest {
        guard let token = token else { throw NotionAPIError.noToken }
        guard let url = URL(string: baseURL + path) else { throw NotionAPIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        return request
    }
    
    func fetchDailySchedule(date: Date) async throws -> DailySchedule? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let titleQuery = "\(dateString) 今日のスケジュール"
        
        // 1. Search for the page
        let searchBody: [String: Any] = [
            "query": titleQuery,
            "filter": [
                "property": "object",
                "value": "page"
            ]
        ]
        
        let searchData = try JSONSerialization.data(withJSONObject: searchBody)
        let searchRequest = try makeRequest(path: "/search", method: "POST", body: searchData)
        
        let (data, response) = try await URLSession.shared.data(for: searchRequest)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NotionAPIError.badResponse(status)
        }
        
        let pageRes = try JSONDecoder().decode(NotionPageResponse.self, from: data)
        guard let page = pageRes.results.first else {
            return nil // ページが存在しない
        }
        
        // 2. Fetch blocks
        let blocksRequest = try makeRequest(path: "/blocks/\(page.id)/children?page_size=100", method: "GET")
        let (blockData, blockResponse) = try await URLSession.shared.data(for: blocksRequest)
        guard let blockHttpRes = blockResponse as? HTTPURLResponse, blockHttpRes.statusCode == 200 else {
            throw NotionAPIError.badResponse((blockResponse as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        
        // Helper to extract texts
        guard let jsonObject = try JSONSerialization.jsonObject(with: blockData) as? [String: Any],
              let results = jsonObject["results"] as? [[String: Any]] else {
            return nil
        }
        
        var extractedTexts: [String] = []
        for block in results {
            guard let type = block["type"] as? String else { continue }
            
            if type == "divider" {
                extractedTexts.append("---")
                continue
            }
            
            if let typeDict = block[type] as? [String: Any],
               let richTexts = typeDict["rich_text"] as? [[String: Any]] {
                
                let combinedText = richTexts.compactMap { $0["plain_text"] as? String }.joined()
                if !combinedText.isEmpty {
                    extractedTexts.append(combinedText)
                }
            }
        }
        
        // 3. Parse texts to items
        let items = ScheduleParser.parseScheduleLines(texts: extractedTexts, targetDate: date)
        
        return DailySchedule(dateString: dateString, items: items, notionPageURL: page.url)
    }
}
