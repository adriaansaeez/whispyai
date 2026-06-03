import Foundation
import Security

struct KeychainStore: Sendable {
    func readAPIKey(for provider: AIProviderKind) throws -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: provider.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            return nil
        }

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw WhispyError.notImplemented("Keychain read failed")
        }

        return value
    }

    func saveAPIKey(_ apiKey: String, for provider: AIProviderKind) throws {
        try deleteAPIKey(for: provider)

        guard let data = apiKey.data(using: .utf8) else {
            throw WhispyError.notImplemented("Failed to encode API key")
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: provider.rawValue,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw WhispyError.notImplemented("Keychain save failed with status \(status)")
        }
    }

    func deleteAPIKey(for provider: AIProviderKind) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: provider.rawValue,
        ]

        SecItemDelete(query as CFDictionary)
    }

    private let serviceName = "com.whispyai.api-keys"
}