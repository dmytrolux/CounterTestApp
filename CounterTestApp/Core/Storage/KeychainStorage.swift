import Foundation
import KeychainAccess

final class KeychainStorage: StorageService {
    private let keychain: Keychain

    init(service: String = Bundle.main.bundleIdentifier ?? "AppKeychain") {
        self.keychain = Keychain(service: service)
    }

    func save(_ value: Any?, forKey key: String) {
        guard let value = value else {
            removeValue(forKey: key)
            return
        }
        
        keychain[key] = "\(value)"
    }

    func value<T>(forKey key: String) -> T? {
        guard let stringValue = keychain[key] else { return nil }

        if T.self == Int.self {
            return Int(stringValue) as? T
        } else if T.self == String.self {
            return stringValue as? T
        }
        
        return nil
    }

    func removeValue(forKey key: String) {
        try? keychain.remove(key)
    }
}
