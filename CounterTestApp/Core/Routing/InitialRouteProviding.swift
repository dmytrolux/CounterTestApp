import Foundation

enum LaunchDestination: String, Equatable, Sendable {
    case counter
    case webView
}

protocol InitialRouteProviding {
    func fetchInitialDestination() async throws -> LaunchDestination
}

struct StaticInitialRouteProvider: InitialRouteProviding {
    let destination: LaunchDestination

    func fetchInitialDestination() async throws -> LaunchDestination {
        destination
    }
}
