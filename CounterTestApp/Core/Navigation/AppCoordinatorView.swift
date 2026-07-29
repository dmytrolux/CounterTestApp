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
        ZStack {
            rootView
            SplashView(viewModel: coordinator.splashViewModel)
                .zIndex(1)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: coordinator.start)
    }

    @ViewBuilder
    private var rootView: some View {
        switch coordinator.route {
        case .counter:
            CounterModuleView(viewModel: coordinator.counterViewModel)
        case .webView:
            WebViewScreen(viewModel: coordinator.webViewViewModel)
        }
    }
}
