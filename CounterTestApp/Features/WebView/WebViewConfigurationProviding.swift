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
            var hostname = window.location.hostname.toLowerCase();
            var isNSQSite = hostname === 'nsq.market' || hostname.endsWith('.nsq.market');
            if (isNSQSite) {
                document.documentElement.setAttribute('data-whiteout-site', 'true');
            }

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

            var style = document.getElementById('whiteout-native-theme');
            if (!style) {
                style = document.createElement('style');
                style.id = 'whiteout-native-theme';
                document.head.appendChild(style);
            }
            style.textContent = `
                html, body, body * {
                    -webkit-user-select: none !important;
                    user-select: none !important;
                    -webkit-touch-callout: none !important;
                }
                input, textarea, select {
                    font-size: 16px !important;
                }
                html[data-whiteout-site] h3[data-whiteout-brand-title] {
                    font-weight: 800 !important;
                }
                html[data-whiteout-site],
                html[data-whiteout-site] body {
                    background-color: #47147A !important;
                }
                html[data-whiteout-site] .col.col-12.col-lg-4 {
                    --bs-primary: #FFBF2E !important;
                    --bs-primary-rgb: 255, 191, 46 !important;
                    color: #FFBF2E !important;
                }
                html[data-whiteout-site] button.navbar-toggler[data-bs-target="#sidebarMenu"] {
                    display: none !important;
                }
            `;

            function applyWhiteOutBranding() {
                if (!isNSQSite) {
                    return;
                }
                document.querySelectorAll('h3').forEach(function(heading) {
                    if (heading.textContent.trim() === 'App testing') {
                        heading.textContent = 'WhiteOut';
                        heading.setAttribute('data-whiteout-brand-title', 'true');
                    }
                });
            }

            function replaceTestVideo() {
                if (!isNSQSite) {
                    return;
                }

                var testVideoID = '5NV6Rdv1a3I';
                var smoothCriminalVideoID = 'h_D3VFfhvs4';
                var urlAttributes = ['src', 'data-src', 'href', 'poster', 'style'];
                var videoIDAttributes = ['videoid', 'video-id', 'data-video-id'];

                document.querySelectorAll('*').forEach(function(element) {
                    urlAttributes.forEach(function(attribute) {
                        var value = element.getAttribute(attribute);
                        if (value && value.indexOf(testVideoID) !== -1) {
                            element.setAttribute(
                                attribute,
                                value.split(testVideoID).join(smoothCriminalVideoID)
                            );
                        }
                    });

                    videoIDAttributes.forEach(function(attribute) {
                        if (element.getAttribute(attribute) === testVideoID) {
                            element.setAttribute(attribute, smoothCriminalVideoID);
                        }
                    });
                });
            }

            function replaceUnsupportedTestAudio() {
                if (!isNSQSite) {
                    return;
                }

                var oggURL = 'https://upload.wikimedia.org/wikipedia/en/8/89/Daft_Punk_-_Get_Lucky.ogg';
                var mp3URL = 'https://upload.wikimedia.org/wikipedia/en/transcoded/8/89/Daft_Punk_-_Get_Lucky.ogg/Daft_Punk_-_Get_Lucky.ogg.mp3';

                document.querySelectorAll('audio source').forEach(function(source) {
                    if (source.getAttribute('src') !== oggURL) {
                        return;
                    }

                    source.setAttribute('src', mp3URL);
                    source.setAttribute('type', 'audio/mpeg');

                    var audio = source.closest('audio');
                    if (audio) {
                        audio.load();
                    }
                });
            }

            function applyNSQCustomizations() {
                applyWhiteOutBranding();
                replaceTestVideo();
                replaceUnsupportedTestAudio();
            }

            if (isNSQSite) {
                applyNSQCustomizations();
                var customizationObserver = new MutationObserver(applyNSQCustomizations);
                customizationObserver.observe(document.documentElement, {
                    childList: true,
                    subtree: true,
                    characterData: true,
                    attributes: true,
                    attributeFilter: [
                        'src', 'data-src', 'href', 'poster', 'style',
                        'type', 'videoid', 'video-id', 'data-video-id'
                    ]
                });
            }

            document.addEventListener('selectstart', function(event) {
                event.preventDefault();
            }, true);
            document.addEventListener('contextmenu', function(event) {
                event.preventDefault();
            }, true);
            document.addEventListener('dragstart', function(event) {
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
