import Foundation
import Security

/// Key-value storage for secrets. Production uses the Keychain;
/// tests use an in-memory implementation.
public protocol SecretStore: Sendable {
    func read(_ key: String) throws -> String?
    func save(_ value: String, for key: String) throws
    func delete(_ key: String) throws
}

public enum SecretStoreError: Error {
    case unexpectedStatus(OSStatus)
    case invalidData
}

/// Generic-password Keychain storage, scoped to a service identifier.
public struct KeychainSecretStore: SecretStore {
    private let service: String

    public init(service: String) {
        self.service = service
    }

    public func read(_ key: String) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw SecretStoreError.invalidData
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw SecretStoreError.unexpectedStatus(status)
        }
    }

    public func save(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        var query = baseQuery(for: key)

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SecretStoreError.unexpectedStatus(addStatus)
            }
        default:
            throw SecretStoreError.unexpectedStatus(updateStatus)
        }
    }

    public func delete(_ key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
