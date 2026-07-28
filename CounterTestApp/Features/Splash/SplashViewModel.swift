import Combine
import Foundation

@MainActor
final class SplashViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case failed(message: String)
    }

    @Published private(set) var state: State = .loading

    private let routeProvider: InitialRouteProviding
    private let analyticsService: AnalyticsServiceProtocol
    private let onDestinationResolved: (LaunchDestination) -> Void
    private var isResolving = false

    init(
        routeProvider: InitialRouteProviding,
        analyticsService: AnalyticsServiceProtocol,
        onDestinationResolved: @escaping (LaunchDestination) -> Void
    ) {
        self.routeProvider = routeProvider
        self.analyticsService = analyticsService
        self.onDestinationResolved = onDestinationResolved
    }

    func load() async {
        guard !isResolving else { return }

        isResolving = true
        defer { isResolving = false }
        state = .loading
        analyticsService.track(event: "splash_loading_started")

        do {
            let destination = try await routeProvider.fetchInitialDestination()
            guard !Task.isCancelled else { return }

            analyticsService.track(
                event: "initial_route_resolved",
                parameters: ["destination": destination.rawValue]
            )
            onDestinationResolved(destination)
        } catch is CancellationError {
            
        } catch {
            state = .failed(message: "Unable to load the app. Please try again.")
            analyticsService.track(
                event: "splash_loading_failed",
                parameters: ["error": String(describing: error)]
            )
        }

    }
}
