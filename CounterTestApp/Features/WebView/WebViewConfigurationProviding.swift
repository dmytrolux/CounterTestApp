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
        configuration.userContentController.addUserScript(webInteractionUserScript)

        return configuration
    }

    private var webInteractionUserScript: WKUserScript {
        let source = #"""
        (function() {
            var viewport = document.querySelector('meta[name="viewport"]');
            if (!viewport) {
                viewport = document.createElement('meta');
                viewport.name = 'viewport';
                document.head.appendChild(viewport);
            }

            viewport.setAttribute(
                'content',
                'width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'
            );

            var style = document.createElement('style');
            style.textContent = `
                html, body, body * {
                    -webkit-user-select: none !important;
                    user-select: none !important;
                    -webkit-touch-callout: none !important;
                }
                input, textarea, select {
                    font-size: 16px !important;
                }
            `;
            document.head.appendChild(style);

            document.addEventListener('selectstart', function(event) {
                event.preventDefault();
            }, true);
            document.addEventListener('contextmenu', function(event) {
                event.preventDefault();
            }, true);
        })();
        """#

        return WKUserScript(
            source: source,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
    }
}
