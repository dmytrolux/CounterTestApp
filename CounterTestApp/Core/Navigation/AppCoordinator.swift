import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    enum Route: Equatable {
        case counter
        case webView
    }

    @Published private(set) var route: Route = .counter

    private let analyticsService: AnalyticsServiceProtocol
    private let routeProvider: InitialRouteProviding
    private let routingDelayNanoseconds: UInt64
    private let storageService: StorageService
    private let webViewURL: URL
    private let webViewConfigurationProvider: WebViewConfigurationProviding
    private let externalURLOpener: ExternalURLOpening
    private let documentPickerPresenter: DocumentPickerPresenting
    private let networkMonitor: NetworkMonitoring
    private var hasStarted = false

    lazy var splashViewModel = SplashViewModel(
        routeProvider: routeProvider,
        routingDelayNanoseconds: routingDelayNanoseconds,
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
        externalURLOpener: externalURLOpener,
        documentPickerPresenter: documentPickerPresenter,
        networkMonitor: networkMonitor,
        analyticsService: analyticsService,
        onProgressUpdated: { [weak self] progress in
            self?.splashViewModel.updateWebViewProgress(progress)
        },
        onInitialLoadFinished: { [weak self] in
            self?.splashViewModel.webViewDidFinishInitialLoad()
        }
    )

    init(
        analyticsService: AnalyticsServiceProtocol,
        routeProvider: InitialRouteProviding,
        routingDelayNanoseconds: UInt64,
        storageService: StorageService,
        webViewURL: URL,
        webViewConfigurationProvider: WebViewConfigurationProviding,
        externalURLOpener: ExternalURLOpening,
        documentPickerPresenter: DocumentPickerPresenting,
        networkMonitor: NetworkMonitoring
    ) {
        self.analyticsService = analyticsService
        self.routeProvider = routeProvider
        self.routingDelayNanoseconds = routingDelayNanoseconds
        self.storageService = storageService
        self.webViewURL = webViewURL
        self.webViewConfigurationProvider = webViewConfigurationProvider
        self.externalURLOpener = externalURLOpener
        self.documentPickerPresenter = documentPickerPresenter
        self.networkMonitor = networkMonitor
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
