import Foundation
import Security

enum KeychainService {
    private static let serviceName = "xin.iristack.deepseek.status.bar"
    private static let accountName = "DeepSeekStatusBar-api-key"
    private static let legacyServiceName = "xin.iristack.deepseek--status-bar"

    @discardableResult
    static func save(apiKey: String) -> OSStatus {
        deleteApiKey()

        guard let data = apiKey.data(using: .utf8) else {
            return errSecParam
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        return SecItemAdd(query as CFDictionary, nil)
    }

    static func loadApiKey() -> String? {
        // 迁移旧 service name 的 Keychain 项到新 service name
        migrateIfNeeded()
        return read(service: serviceName)
    }

    private static func migrateIfNeeded() {
        guard let oldKey = read(service: legacyServiceName), read(service: serviceName) == nil else {
            return
        }
        // 写入新 service name
        guard let data = oldKey.data(using: .utf8) else { return }
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        _ = SecItemAdd(addQuery as CFDictionary, nil)
        // 删除旧项
        let delQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyServiceName,
            kSecAttrAccount as String: accountName
        ]
        _ = SecItemDelete(delQuery as CFDictionary)
    }

    private static func read(service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func deleteApiKey() -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]

        return SecItemDelete(query as CFDictionary)
    }
}
