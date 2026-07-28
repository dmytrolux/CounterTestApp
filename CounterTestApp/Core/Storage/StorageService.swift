import Foundation

protocol StorageService {
    func save(_ value: Any?, forKey key: String)
    func value<T>(forKey key: String) -> T?
    func removeValue(forKey key: String)
}

