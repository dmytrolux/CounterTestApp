import Foundation

protocol AnalyticsServiceProtocol {
    func track(event: String, parameters: [String: String])
}

extension AnalyticsServiceProtocol {
    func track(event: String) {
        track(event: event, parameters: [:])
    }
}
