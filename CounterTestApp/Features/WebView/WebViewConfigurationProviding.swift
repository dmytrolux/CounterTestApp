import WebKit

protocol WebViewConfigurationProviding {
    func makeConfiguration() -> WKWebViewConfiguration
}

struct DefaultWebViewConfigurationProvider: WebViewConfigurationProviding {
    private let applicationNameForUserAgent: String?

    init(applicationNameForUserAgent: String? = "CounterTestApp/1.0") {
        self.applicationNameForUserAgent = applicationNameForUserAgent
    }

    func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()

        configuration.websiteDataStore = .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.applicationNameForUserAgent = applicationNameForUserAgent

        return configuration
    }
}
