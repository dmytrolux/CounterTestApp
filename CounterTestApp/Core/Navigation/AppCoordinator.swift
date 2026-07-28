import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    enum Route: Equatable {
        case splash
        case counter
        case webView
    }

    @Published private(set) var route: Route = .splash

    private let analyticsService: AnalyticsServiceProtocol
    private let routeProvider: InitialRouteProviding
    private let storageService: StorageService
    private let webViewURL: URL
    private let webViewConfigurationProvider: WebViewConfigurationProviding
    private var hasStarted = false

    lazy var splashViewModel = SplashViewModel(
        routeProvider: routeProvider,
        analyticsService: analyticsService
    ) { [weak self] destination in
        self?.show(destination)
    }

    lazy var counterViewModel = CounterViewModel(
        storage: storageService,
        analyticsService: analyticsService
    )

    lazy var webViewViewModel = WebViewViewModel(
        url: webViewURL,
        configurationProvider: webViewConfigurationProvider,
        analyticsService: analyticsService
    )

    init(
        analyticsService: AnalyticsServiceProtocol,
        routeProvider: InitialRouteProviding,
        storageService: StorageService,
        webViewURL: URL,
        webViewConfigurationProvider: WebViewConfigurationProviding
    ) {
        self.analyticsService = analyticsService
        self.routeProvider = routeProvider
        self.storageService = storageService
        self.webViewURL = webViewURL
        self.webViewConfigurationProvider = webViewConfigurationProvider
    }

    func start() {
        guard !hasStarted else { return }

        hasStarted = true
        analyticsService.track(event: "app_started")
    }

    private func show(_ destination: LaunchDestination) {
        switch destination {
        case .counter:
            route = .counter
        case .webView:
            route = .webView
        }
    }
}
