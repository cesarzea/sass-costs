import Foundation
import Security

enum Keychain {
    /// Service name of the IMAP app passwords (`security add-generic-password -s sass-costs-imap -a <email> -w`).
    static let imapService = "sass-costs-imap"

    enum Failure: LocalizedError, Equatable {
        case notFound(account: String, status: OSStatus)

        var errorDescription: String? {
            switch self {
            case let .notFound(account, status):
                return "No Keychain password for \(account) (status \(status))"
            }
        }
    }

    static func password(account: String, service: String = imapService) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let password = String(bytes: data, encoding: .utf8) else {
            throw Failure.notFound(account: account, status: status)
        }
        return password
    }
}
