import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel

    init(viewModel: SplashViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo, Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "plus.forwardslash.minus")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(.white)
                    .accessibilityHidden(true)

                Text("CounterTestApp")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                content
            }
            .padding(32)
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading…")
                .progressViewStyle(.circular)
                .tint(.white)
                .foregroundColor(.white)
                .accessibilityIdentifier("splash.loader")

        case let .failed(message):
            VStack(spacing: 16) {
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Button("Retry") {
                    Task {
                        await viewModel.load()
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("splash.retry")
            }
        }
    }
}
