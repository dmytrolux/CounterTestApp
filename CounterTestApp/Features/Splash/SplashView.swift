import SwiftUI

struct SplashView: View {
    @StateObject private var viewModel: SplashViewModel

    init(viewModel: SplashViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isVisible {
                splashContent
                    .transition(.identity)
            }
        }
        .animation(nil, value: viewModel.isVisible)
        .task {
            await viewModel.load()
        }
    }

    private var splashContent: some View {
        ZStack {
            Color.indigo
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.indigo, Color.purple],
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
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            VStack(spacing: 12) {
                ProgressView(value: viewModel.progress, total: 1)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(maxWidth: 220)

                Text("\(viewModel.loadingMessage) \(Int(viewModel.progress * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.white)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(viewModel.loadingMessage)
            .accessibilityValue("\(Int(viewModel.progress * 100)) percent")
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
