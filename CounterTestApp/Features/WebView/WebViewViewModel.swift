import Combine
import Foundation

@MainActor
final class WebViewViewModel: ObservableObject {
    let request: URLRequest
    let configurationProvider: WebViewConfigurationProviding

    init(
        url: URL,
        configurationProvider: WebViewConfigurationProviding,
        analyticsService: AnalyticsServiceProtocol
    ) {
        request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30
        )
        self.configurationProvider = configurationProvider

        analyticsService.track(
            event: "web_view_opened",
            parameters: ["url": url.absoluteString]
        )
    }
}
