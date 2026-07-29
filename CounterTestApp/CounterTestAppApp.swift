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
        guard let webViewURL = URL(string: "https://lk.nsq.market/en/tools/testing") else {
            preconditionFailure("The configured WebView URL must be valid.")
        }

        let analyticsService = ConsoleAnalyticsService()
        let storageService = UserDefaultsStorage()
        let routingDelayNanoseconds = MockRemoteConfigRoutingService.defaultLoadingDelayNanoseconds
        let routeProvider = MockRemoteConfigRoutingService(
            storage: storageService,
            firstDestination: .counter,
            loadingDelayNanoseconds: routingDelayNanoseconds
        )
        let webViewConfigurationProvider = DefaultWebViewConfigurationProvider()
        let externalURLOpener = SystemExternalURLOpener()
        _coordinator = StateObject(
            wrappedValue: AppCoordinator(
                analyticsService: analyticsService,
                routeProvider: routeProvider,
                routingDelayNanoseconds: routingDelayNanoseconds,
                storageService: storageService,
                webViewURL: webViewURL,
                webViewConfigurationProvider: webViewConfigurationProvider,
                externalURLOpener: externalURLOpener
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: coordinator)
        }
    }
}
