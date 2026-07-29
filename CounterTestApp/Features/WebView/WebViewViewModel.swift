import Combine
import Foundation
import WebKit

struct WebViewLoadError: Equatable {
    enum Kind: Equatable {
        case offline
        case general
    }

    let kind: Kind
    let title: String
    let message: String
    let systemImage: String
}

@MainActor
final class WebViewViewModel: ObservableObject {
    private enum WebKitErrorCode {
        static let frameLoadInterruptedByPolicyChange = 102
    }

    @Published private(set) var estimatedProgress = 0.0
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var loadError: WebViewLoadError?
    @Published private(set) var isRetrying = false
    @Published private(set) var isLoading = false
    @Published private(set) var isOffline = false

    private(set) var request: URLRequest
    let configurationProvider: WebViewConfigurationProviding
    let externalURLOpener: ExternalURLOpening
    let documentPickerPresenter: DocumentPickerPresenting

    private let analyticsService: AnalyticsServiceProtocol
    private let networkMonitor: NetworkMonitoring
    private let onProgressUpdated: (Double) -> Void
    private let onInitialLoadFinished: () -> Void
    private var initialLoadDidFinish = false
    private var goBackAction: (() -> Void)?
    private var goForwardAction: (() -> Void)?
    private var retryAction: (() -> Void)?
    private var navigateAction: ((URLRequest) -> Void)?

    init(
        url: URL,
        configurationProvider: WebViewConfigurationProviding,
        externalURLOpener: ExternalURLOpening,
        documentPickerPresenter: DocumentPickerPresenting,
        networkMonitor: NetworkMonitoring,
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
        self.documentPickerPresenter = documentPickerPresenter
        self.networkMonitor = networkMonitor
        self.analyticsService = analyticsService
        self.onProgressUpdated = onProgressUpdated
        self.onInitialLoadFinished = onInitialLoadFinished

        analyticsService.track(
            event: "web_view_opened",
            parameters: ["url": url.absoluteString]
        )

        networkMonitor.start { [weak self] isConnected in
            self?.networkStatusDidChange(isConnected: isConnected)
        }
    }

    func updateEstimatedProgress(_ progress: Double) {
        estimatedProgress = min(max(progress, 0), 1)
        onProgressUpdated(estimatedProgress)
    }

    func bindNavigation(
        goBack: @escaping () -> Void,
        goForward: @escaping () -> Void,
        retry: @escaping () -> Void,
        navigate: @escaping (URLRequest) -> Void
    ) {
        goBackAction = goBack
        goForwardAction = goForward
        retryAction = retry
        navigateAction = navigate
    }

    func updateNavigationState(canGoBack: Bool, canGoForward: Bool) {
        if self.canGoBack != canGoBack {
            self.canGoBack = canGoBack
        }
        if self.canGoForward != canGoForward {
            self.canGoForward = canGoForward
        }
    }

    func unbindNavigation() {
        goBackAction = nil
        goForwardAction = nil
        retryAction = nil
        navigateAction = nil
    }

    func goBack() {
        guard canGoBack else { return }
        analyticsService.track(event: "web_view_back_tapped")
        goBackAction?()
    }

    func goForward() {
        guard canGoForward else { return }
        analyticsService.track(event: "web_view_forward_tapped")
        goForwardAction?()
    }

    func retry() {
        guard loadError != nil, !isRetrying, !isOffline else { return }
        isRetrying = true
        isLoading = true
        estimatedProgress = 0
        analyticsService.track(
            event: "web_view_retry_tapped",
            parameters: ["url": request.url?.absoluteString ?? "unknown"]
        )
        retryAction?()
    }

    func navigate(to url: URL) {
        let newRequest = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 30
        )
        request = newRequest
        loadError = nil
        analyticsService.track(
            event: "web_view_deep_link_requested",
            parameters: ["url": url.absoluteString]
        )
        navigateAction?(newRequest)
    }

    func navigationDidStart(url: URL?) {
        isLoading = true
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

        loadError = nil
        isRetrying = false
        isLoading = false

        guard !initialLoadDidFinish else { return }
        initialLoadDidFinish = true
        estimatedProgress = 1
        onProgressUpdated(1)
        onInitialLoadFinished()
    }

    func navigationDidFail(url: URL?, error: Error) {
        let nsError = error as NSError
        guard !isExpectedNavigationCancellation(nsError) else {
            analyticsService.track(
                event: "web_view_navigation_cancelled",
                parameters: [
                    "url": url?.absoluteString ?? "unknown",
                    "code": String(nsError.code)
                ]
            )
            return
        }

        analyticsService.track(
            event: "web_view_load_failed",
            parameters: [
                "url": url?.absoluteString ?? "unknown",
                "error": String(describing: error)
            ]
        )

        let offlineCodes: Set<Int> = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorInternationalRoamingOff,
            NSURLErrorDataNotAllowed
        ]
        let isOffline = nsError.domain == NSURLErrorDomain && offlineCodes.contains(nsError.code)
        showLoadError(
            WebViewLoadError(
                kind: isOffline ? .offline : .general,
                title: isOffline ? "No Internet Connection" : "Unable to Load Page",
                message: isOffline
                    ? "Check your connection and try again."
                    : "Something went wrong while loading this page.",
                systemImage: isOffline ? "wifi.slash" : "exclamationmark.triangle"
            )
        )
    }

    private func isExpectedNavigationCancellation(_ error: NSError) -> Bool {
        if error.domain == NSURLErrorDomain,
           error.code == NSURLErrorCancelled {
            return true
        }

        return error.domain == WKError.errorDomain
            && error.code == WebKitErrorCode.frameLoadInterruptedByPolicyChange
    }

    func navigationDidReceiveHTTPError(statusCode: Int) {
        analyticsService.track(
            event: "web_view_http_error",
            parameters: ["status_code": String(statusCode)]
        )
        showLoadError(
            WebViewLoadError(
                kind: .general,
                title: "Page Unavailable",
                message: "The server returned an error (\(statusCode)). Please try again.",
                systemImage: "exclamationmark.triangle"
            )
        )
    }

    func webContentProcessDidTerminate() {
        analyticsService.track(event: "web_view_process_terminated", parameters: [:])
        showLoadError(
            WebViewLoadError(
                kind: .general,
                title: "Page Stopped Responding",
                message: "Reload the page to continue.",
                systemImage: "arrow.clockwise.circle"
            )
        )
    }

    private func showLoadError(_ error: WebViewLoadError) {
        loadError = error
        isRetrying = false
        isLoading = false

        guard !initialLoadDidFinish else { return }
        initialLoadDidFinish = true
        estimatedProgress = 1
        onProgressUpdated(1)
        onInitialLoadFinished()
    }

    private func networkStatusDidChange(isConnected: Bool) {
        isOffline = !isConnected
        analyticsService.track(
            event: "network_status_changed",
            parameters: ["is_connected": String(isConnected)]
        )

        guard !isConnected else { return }
        showLoadError(
            WebViewLoadError(
                kind: .offline,
                title: "No Internet Connection",
                message: "Check your connection and try again.",
                systemImage: "wifi.slash"
            )
        )
    }

    func trackExternalNavigation(url: URL) {
        analyticsService.track(
            event: "web_view_external_url_opened",
            parameters: ["url": url.absoluteString]
        )
    }

    func trackPopup(url: URL?) {
        analyticsService.track(
            event: "web_view_popup_opened",
            parameters: ["url": url?.absoluteString ?? "unknown"]
        )
    }

    func trackMediaPermission(type: String, granted: Bool) {
        analyticsService.track(
            event: "web_view_media_permission_resolved",
            parameters: ["type": type, "granted": String(granted)]
        )
    }

    func trackDownloadStarted(filename: String) {
        analyticsService.track(
            event: "web_view_download_started",
            parameters: ["filename": filename]
        )
    }

    func trackDownloadFinished(filename: String) {
        analyticsService.track(
            event: "web_view_download_finished",
            parameters: ["filename": filename]
        )
    }

    func trackDownloadFailed(error: Error) {
        analyticsService.track(
            event: "web_view_download_failed",
            parameters: ["error": String(describing: error)]
        )
    }

    func trackFileImport(filesCount: Int?, cancelled: Bool) {
        analyticsService.track(
            event: "web_view_file_import_resolved",
            parameters: [
                "cancelled": String(cancelled),
                "files_count": String(filesCount ?? 0)
            ]
        )
    }
}
