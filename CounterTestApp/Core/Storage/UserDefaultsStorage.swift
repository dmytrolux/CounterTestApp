import Foundation

final class UserDefaultsStorage: StorageService {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func save(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    func value<T>(forKey key: String) -> T? {
        userDefaults.object(forKey: key) as? T
    }

    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
