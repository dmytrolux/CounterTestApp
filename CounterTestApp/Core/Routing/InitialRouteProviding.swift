import Foundation

enum LaunchDestination: String, Equatable, Sendable {
    case counter
    case webView
}

protocol InitialRouteProviding {
    func fetchInitialDestination() async throws -> LaunchDestination
}
