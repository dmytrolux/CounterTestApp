import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let request: URLRequest
    let configurationProvider: WebViewConfigurationProviding

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(
            frame: .zero,
            configuration: configurationProvider.makeConfiguration()
        )
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground

        context.coordinator.lastRequestedURL = request.url
        webView.load(request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard request.url != context.coordinator.lastRequestedURL else { return }

        context.coordinator.lastRequestedURL = request.url
        webView.load(request)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
    }

    final class Coordinator {
        var lastRequestedURL: URL?
    }
}
