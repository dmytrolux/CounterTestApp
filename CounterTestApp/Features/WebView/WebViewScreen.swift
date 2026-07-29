import SwiftUI

struct WebViewScreen: View {
    @StateObject private var viewModel: WebViewViewModel

    init(viewModel: WebViewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            WebViewContainer(viewModel: viewModel)

            if viewModel.isLoading, viewModel.loadError == nil {
                VStack {
                    ProgressView(value: viewModel.estimatedProgress, total: 1)
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .accessibilityIdentifier("web.loading.progress")
                    Spacer()
                }
            }

            if let error = viewModel.loadError {
                errorView(error)
            }
        }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                navigationBar
            }
    }

    private func errorView(_ error: WebViewLoadError) -> some View {
        VStack(spacing: 18) {
            Image(systemName: error.systemImage)
                .font(.system(size: 46, weight: .medium))
                .foregroundColor(.white)

            Text(error.title)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)

            Text(error.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white.opacity(0.7))

            Button(action: viewModel.retry) {
                HStack(spacing: 10) {
                    if viewModel.isRetrying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(retryButtonTitle)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(viewModel.isRetrying || viewModel.isOffline)
            .accessibilityIdentifier("web.error.retry")
            .padding(.top, 6)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var retryButtonTitle: String {
        if viewModel.isOffline {
            return "Waiting for Network…"
        }
        return viewModel.isRetrying ? "Retrying…" : "Try Again"
    }

    private var navigationBar: some View {
        HStack(spacing: 28) {
            navigationButton(
                systemName: "chevron.left",
                accessibilityLabel: "Назад",
                accessibilityIdentifier: "web.navigation.back",
                isEnabled: viewModel.canGoBack,
                action: viewModel.goBack
            )

            navigationButton(
                systemName: "chevron.right",
                accessibilityLabel: "Вперед",
                accessibilityIdentifier: "web.navigation.forward",
                isEnabled: viewModel.canGoForward,
                action: viewModel.goForward
            )

            Spacer()
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(Color.black.ignoresSafeArea(edges: .bottom))
    }

    private func navigationButton(
        systemName: String,
        accessibilityLabel: String,
        accessibilityIdentifier: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 19, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .foregroundColor(isEnabled ? .white : Color.white.opacity(0.3))
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
