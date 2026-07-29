//
//  CounterTestAppApp.swift
//  CounterTestApp
//
//  Created by Дмитро on 28.07.2026.
//

import SwiftUI

@main
struct CounterTestAppApp: App {
    @StateObject private var coordinator: AppCoordinator

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let isUITesting = arguments.contains("--ui-testing")
        let forcedDestination: LaunchDestination? = arguments.contains("--force-counter")
            ? .counter
            : arguments.contains("--force-webview") ? .webView : nil
        let webURLString = isUITesting && forcedDestination == .webView
            ? "data:text/html,<html><body>UI%20Test</body></html>"
            : "https://lk.nsq.market/en/tools/testing"

        guard let webViewURL = URL(string: webURLString) else {
            preconditionFailure("The configured WebView URL must be valid.")
        }
        guard let notificationURL = URL(string: "https://www.apple.com/") else {
            preconditionFailure("The notification URL must be valid.")
        }

        let analyticsService = ConsoleAnalyticsService()
        let storageService = UserDefaultsStorage()
        let routingDelayNanoseconds = MockRemoteConfigRoutingService.defaultLoadingDelayNanoseconds
        let routeProvider: InitialRouteProviding = forcedDestination.map(StaticInitialRouteProvider.init)
            ?? MockRemoteConfigRoutingService(
                storage: storageService,
                firstDestination: .counter,
                loadingDelayNanoseconds: routingDelayNanoseconds
            )
        let webViewConfigurationProvider = DefaultWebViewConfigurationProvider()
        let externalURLOpener = SystemExternalURLOpener()
        let documentPickerPresenter = SystemDocumentPickerPresenter()
        let networkMonitor: NetworkMonitoring = isUITesting
            ? AlwaysConnectedNetworkMonitor()
            : NWPathNetworkMonitor()
        let notificationService: NotificationServiceProtocol = isUITesting
            ? NoopNotificationService()
            : NotificationService(
                destinationURL: notificationURL,
                analyticsService: analyticsService
            )
        _coordinator = StateObject(
            wrappedValue: AppCoordinator(
                analyticsService: analyticsService,
                routeProvider: routeProvider,
                routingDelayNanoseconds: routingDelayNanoseconds,
                storageService: storageService,
                webViewURL: webViewURL,
                webViewConfigurationProvider: webViewConfigurationProvider,
                externalURLOpener: externalURLOpener,
                documentPickerPresenter: documentPickerPresenter,
                networkMonitor: networkMonitor,
                notificationService: notificationService
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: coordinator)
        }
    }
}
