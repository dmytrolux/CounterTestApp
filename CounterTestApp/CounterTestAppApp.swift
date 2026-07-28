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
        let routeProvider = MockRemoteConfigRoutingService(
            storage: storageService,
            firstDestination: .counter
        )
        let webViewConfigurationProvider = DefaultWebViewConfigurationProvider()
        _coordinator = StateObject(
            wrappedValue: AppCoordinator(
                analyticsService: analyticsService,
                routeProvider: routeProvider,
                storageService: storageService,
                webViewURL: webViewURL,
                webViewConfigurationProvider: webViewConfigurationProvider
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: coordinator)
        }
    }
}
