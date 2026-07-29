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
    private let notificationService: NotificationServiceProtocol
    private var hasStarted = false
    private var isBackgroundNotificationScheduled = false

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
        networkMonitor: NetworkMonitoring,
        notificationService: NotificationServiceProtocol
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
        self.notificationService = notificationService
        notificationService.configure { [weak self] url in
            self?.openNotificationDestination(url)
        }
    }

    func start() {
        guard !hasStarted else { return }

        hasStarted = true
        analyticsService.track(event: "app_started")
        notificationService.requestAuthorization()
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        analyticsService.track(
            event: "app_scene_phase_changed",
            parameters: ["phase": scenePhase.analyticsName]
        )
        switch scenePhase {
        case .active:
            isBackgroundNotificationScheduled = false
            notificationService.cancelPendingBackgroundNotification()
        case .inactive, .background:
            guard !isBackgroundNotificationScheduled else { return }
            isBackgroundNotificationScheduled = true
            analyticsService.track(
                event: "background_notification_requested",
                parameters: ["delay_seconds": "10"]
            )
            notificationService.scheduleBackgroundNotification(after: 10)
        @unknown default:
            break
        }
    }

    private func show(_ destination: LaunchDestination) {
        analyticsService.track(
            event: "route_presented",
            parameters: ["destination": destination.rawValue]
        )
        switch destination {
        case .counter:
            route = .counter
        case .webView:
            _ = webViewViewModel
            route = .webView
        }
    }

    private func openNotificationDestination(_ url: URL) {
        analyticsService.track(
            event: "notification_opened",
            parameters: ["url": url.absoluteString]
        )
        splashViewModel.dismiss()
        let viewModel = webViewViewModel
        viewModel.navigate(to: url)
        route = .webView
    }
}

private extension ScenePhase {
    var analyticsName: String {
        switch self {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}
