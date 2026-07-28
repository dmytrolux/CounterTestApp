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
        let analyticsService = ConsoleAnalyticsService()
        let routeProvider = MockRemoteConfigRoutingService(destination: .webView)
        _coordinator = StateObject(
            wrappedValue: AppCoordinator(
                analyticsService: analyticsService,
                routeProvider: routeProvider
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: coordinator)
        }
    }
}
