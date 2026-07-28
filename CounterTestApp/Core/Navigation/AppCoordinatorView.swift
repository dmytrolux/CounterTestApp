//
//  AppCoordinatorView.swift
//  CounterTestApp
//
//  Created by Дмитро on 28.07.2026.
//

import SwiftUI

struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        rootView
            .onAppear(perform: coordinator.start)
    }

    @ViewBuilder
    private var rootView: some View {
        switch coordinator.route {
        case .splash:
            SplashView(viewModel: coordinator.splashViewModel)
        case .counter:
            CounterModuleView(viewModel: coordinator.counterViewModel)
        case .webView:
            WebViewScreen(viewModel: coordinator.webViewViewModel)
        }
    }
}
