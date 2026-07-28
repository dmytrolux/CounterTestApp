import Foundation

struct MockRemoteConfigRoutingService: InitialRouteProviding {
    private let destination: LaunchDestination
    private let loadingDelayNanoseconds: UInt64

    init(
        destination: LaunchDestination = .webView,
        loadingDelayNanoseconds: UInt64 = 1_500_000_000
    ) {
        self.destination = destination
        self.loadingDelayNanoseconds = loadingDelayNanoseconds
    }

    func fetchInitialDestination() async throws -> LaunchDestination {
        try await Task.sleep(nanoseconds: loadingDelayNanoseconds)
        try Task.checkCancellation()
        return destination
    }
}
