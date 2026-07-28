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
            DestinationPlaceholderView(title: "Counter Game")
        case .webView:
            DestinationPlaceholderView(title: "WebView")
        }
    }
}

private struct DestinationPlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title.bold())
            Text("This flow will be implemented in the next development step.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
