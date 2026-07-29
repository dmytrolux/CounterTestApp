import Combine
import Foundation

@MainActor
final class WebViewViewModel: ObservableObject {
    @Published private(set) var estimatedProgress = 0.0

    let request: URLRequest
    let configurationProvider: WebViewConfigurationProviding
    let externalURLOpener: ExternalURLOpening

    private let analyticsService: AnalyticsServiceProtocol
    private let onProgressUpdated: (Double) -> Void
    private let onInitialLoadFinished: () -> Void
    private var initialLoadDidFinish = false

    init(
        url: URL,
        configurationProvider: WebViewConfigurationProviding,
        externalURLOpener: ExternalURLOpening,
        analyticsService: AnalyticsServiceProtocol,
        onProgressUpdated: @escaping (Double) -> Void,
        onInitialLoadFinished: @escaping () -> Void
    ) {
        request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30
        )
        self.configurationProvider = configurationProvider
        self.externalURLOpener = externalURLOpener
        self.analyticsService = analyticsService
        self.onProgressUpdated = onProgressUpdated
        self.onInitialLoadFinished = onInitialLoadFinished

        analyticsService.track(
            event: "web_view_opened",
            parameters: ["url": url.absoluteString]
        )
    }

    func updateEstimatedProgress(_ progress: Double) {
        estimatedProgress = min(max(progress, 0), 1)
        onProgressUpdated(estimatedProgress)
    }

    func navigationDidStart(url: URL?) {
        analyticsService.track(
            event: "web_view_load_started",
            parameters: ["url": url?.absoluteString ?? "unknown"]
        )
    }

    func navigationDidRedirect(url: URL?) {
        analyticsService.track(
            event: "web_view_redirect_received",
            parameters: ["url": url?.absoluteString ?? "unknown"]
        )
    }

    func navigationDidFinish(url: URL?) {
        analyticsService.track(
            event: "web_view_load_finished",
            parameters: ["url": url?.absoluteString ?? "unknown"]
        )

        guard !initialLoadDidFinish else { return }
        initialLoadDidFinish = true
        estimatedProgress = 1
        onProgressUpdated(1)
        onInitialLoadFinished()
    }

    func navigationDidFail(url: URL?, error: Error) {
        analyticsService.track(
            event: "web_view_load_failed",
            parameters: [
                "url": url?.absoluteString ?? "unknown",
                "error": String(describing: error)
            ]
        )
    }

    func trackExternalNavigation(url: URL) {
        analyticsService.track(
            event: "web_view_external_url_opened",
            parameters: ["url": url.absoluteString]
        )
    }
}
