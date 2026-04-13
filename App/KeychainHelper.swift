import Foundation
import Security

final class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    func save(_ data: Data, service: String, account: String) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary

        let status = SecItemAdd(query, nil)

        if status == errSecDuplicateItem {
            let query = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary

            let attributesToUpdate = [kSecValueData: data] as CFDictionary

            SecItemUpdate(query, attributesToUpdate)
        }
    }

    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        SecItemCopyMatching(query, &result)

        return (result as? Data)
    }

    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary

        SecItemDelete(query)
    }
}

extension KeychainHelper {
    func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        save(data, service: "com.example.NotionSchedule", account: "notion-api-token")
    }

    func readToken() -> String? {
        guard let data = read(service: "com.example.NotionSchedule", account: "notion-api-token") else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func deleteToken() {
        delete(service: "com.example.NotionSchedule", account: "notion-api-token")
    }
}
