import Combine
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    enum Route: Equatable {
        case initial
    }

    @Published private(set) var route: Route = .initial

    private let analyticsService: AnalyticsServiceProtocol
    private var hasStarted = false

    init(analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }

    func start() {
        guard !hasStarted else { return }

        hasStarted = true
        analyticsService.track(event: "app_started")
    }
}

struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        rootView
            .onAppear(perform: coordinator.start)
    }

    @ViewBuilder
    private var rootView: some View {
        switch coordinator.route {
        case .initial:
            ContentView()
        }
    }
}
