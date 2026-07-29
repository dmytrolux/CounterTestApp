import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(
            frame: .zero,
            configuration: viewModel.configurationProvider.makeConfiguration()
        )
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.scrollView.backgroundColor = .systemBackground
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        webView.scrollView.alwaysBounceHorizontal = false

        webView.navigationDelegate = context.coordinator
        context.coordinator.observeProgress(of: webView)
        context.coordinator.lastRequestedURL = viewModel.request.url
        webView.load(viewModel.request)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard viewModel.request.url != context.coordinator.lastRequestedURL else { return }

        context.coordinator.lastRequestedURL = viewModel.request.url
        webView.load(viewModel.request)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        coordinator.stopObservingProgress()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastRequestedURL: URL?

        private let viewModel: WebViewViewModel
        private var progressObservation: NSKeyValueObservation?

        init(viewModel: WebViewViewModel) {
            self.viewModel = viewModel
        }

        func observeProgress(of webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) {
                [weak viewModel] _, change in
                guard let progress = change.newValue,
                      let viewModel else { return }
                Task { @MainActor [viewModel] in
                    viewModel.updateEstimatedProgress(progress)
                }
            }
        }

        func stopObservingProgress() {
            progressObservation?.invalidate()
            progressObservation = nil
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            let scheme = url.scheme?.lowercased()
            let webSchemes = ["http", "https", "about", "data", "blob", "javascript"]

            guard let scheme, webSchemes.contains(scheme) else {
                viewModel.trackExternalNavigation(url: url)
                viewModel.externalURLOpener.open(url)
                decisionHandler(.cancel)
                return
            }

            if navigationAction.navigationType == .linkActivated,
               isExternalHost(url) {
                viewModel.trackExternalNavigation(url: url)
                viewModel.externalURLOpener.open(url)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
            viewModel.navigationDidStart(url: webView.url)
        }

        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?) {
            viewModel.navigationDidRedirect(url: webView.url)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            viewModel.navigationDidFinish(url: webView.url)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
            viewModel.navigationDidFail(url: webView.url, error: error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
            viewModel.navigationDidFail(url: webView.url, error: error)
        }

        private func isExternalHost(_ url: URL) -> Bool {
            guard let initialHost = viewModel.request.url?.host?.lowercased(),
                  let destinationHost = url.host?.lowercased() else {
                return false
            }

            return destinationHost != initialHost && !destinationHost.hasSuffix(".\(initialHost)")
        }
    }
}
