import Combine
import Foundation

@MainActor
final class SplashViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case failed(message: String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var progress = 0.0
    @Published private(set) var loadingMessage = "Preparing…"
    @Published private(set) var isVisible = true

    private let routeProvider: InitialRouteProviding
    private let routingDelayNanoseconds: UInt64
    private let analyticsService: AnalyticsServiceProtocol
    private let onDestinationResolved: (LaunchDestination) -> Void
    private var isResolving = false
    private var resolvedDestination: LaunchDestination?
    private var routingProgressTask: Task<Void, Never>?
    private var webViewDismissalTask: Task<Void, Never>?
    private var isExternallyDismissed = false

    init(
        routeProvider: InitialRouteProviding,
        routingDelayNanoseconds: UInt64,
        analyticsService: AnalyticsServiceProtocol,
        onDestinationResolved: @escaping (LaunchDestination) -> Void
    ) {
        self.routeProvider = routeProvider
        self.routingDelayNanoseconds = routingDelayNanoseconds
        self.analyticsService = analyticsService
        self.onDestinationResolved = onDestinationResolved
    }

    func load() async {
        guard !isResolving, !isExternallyDismissed else { return }

        isResolving = true
        defer { isResolving = false }
        state = .loading
        progress = 0
        loadingMessage = "Preparing…"
        isVisible = true
        resolvedDestination = nil
        startRoutingProgress()
        analyticsService.track(event: "splash_loading_started")

        do {
            let destination = try await routeProvider.fetchInitialDestination()
            guard !Task.isCancelled, !isExternallyDismissed else { return }
            routingProgressTask?.cancel()
            resolvedDestination = destination

            analyticsService.track(
                event: "initial_route_resolved",
                parameters: ["destination": destination.rawValue]
            )
            onDestinationResolved(destination)

            switch destination {
            case .counter:
                progress = 1
                isVisible = false
            case .webView:
                progress = max(progress, 0.35)
                loadingMessage = "Loading game…"
            }
        } catch is CancellationError {
            routingProgressTask?.cancel()
        } catch {
            routingProgressTask?.cancel()
            state = .failed(message: "Unable to load the app. Please try again.")
            analyticsService.track(
                event: "splash_loading_failed",
                parameters: ["error": String(describing: error)]
            )
        }
    }

    func updateWebViewProgress(_ webProgress: Double) {
        guard resolvedDestination == .webView, isVisible else { return }
        let normalizedProgress = min(max(webProgress, 0), 1)
        progress = max(progress, 0.35 + normalizedProgress * 0.65)
    }

    func webViewDidFinishInitialLoad() {
        guard resolvedDestination == .webView, isVisible else { return }

        progress = 1
        loadingMessage = "Ready"
        webViewDismissalTask?.cancel()
        webViewDismissalTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.isVisible = false
        }
    }

    func dismiss() {
        isExternallyDismissed = true
        routingProgressTask?.cancel()
        webViewDismissalTask?.cancel()
        isVisible = false
    }

    private func startRoutingProgress() {
        routingProgressTask?.cancel()
        let steps: UInt64 = 20
        let stepDelay = max(routingDelayNanoseconds / steps, 1)

        routingProgressTask = Task { [weak self] in
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: stepDelay)
                guard !Task.isCancelled else { return }
                self?.progress = Double(step) / Double(steps) * 0.35
            }
        }
    }

    deinit {
        routingProgressTask?.cancel()
        webViewDismissalTask?.cancel()
    }
}
