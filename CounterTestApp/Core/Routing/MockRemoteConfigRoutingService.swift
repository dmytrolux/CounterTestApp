import Foundation

struct MockRemoteConfigRoutingService: InitialRouteProviding {
    private enum StorageKey {
        static let lastDestination = "routing.lastDestination"
    }

    private let storage: StorageService
    private let firstDestination: LaunchDestination
    private let loadingDelayNanoseconds: UInt64

    init(
        storage: StorageService,
        firstDestination: LaunchDestination = .counter,
        loadingDelayNanoseconds: UInt64 = 1_500_000_000
    ) {
        self.storage = storage
        self.firstDestination = firstDestination
        self.loadingDelayNanoseconds = loadingDelayNanoseconds
    }

    func fetchInitialDestination() async throws -> LaunchDestination {
        try await Task.sleep(nanoseconds: loadingDelayNanoseconds)
        try Task.checkCancellation()

        let lastDestinationRawValue: String? = storage.value(forKey: StorageKey.lastDestination)
        let lastDestination = lastDestinationRawValue.flatMap(LaunchDestination.init(rawValue:))
        let destination: LaunchDestination

        switch lastDestination {
        case .counter:
            destination = .webView
        case .webView:
            destination = .counter
        case nil:
            destination = firstDestination
        }

        storage.save(destination.rawValue, forKey: StorageKey.lastDestination)
        return destination
    }
}
