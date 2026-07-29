import AVFoundation
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
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.allowsLinkPreview = false

        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        context.coordinator.observe(of: webView)
        context.coordinator.disableDragInteractions(in: webView)
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
        webView.uiDelegate = nil
        coordinator.stopObserving()
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
        var lastRequestedURL: URL?

        private let viewModel: WebViewViewModel
        private var progressObservation: NSKeyValueObservation?
        private var canGoBackObservation: NSKeyValueObservation?
        private var canGoForwardObservation: NSKeyValueObservation?
        private var downloadDestinations: [ObjectIdentifier: URL] = [:]
        private var lastMainFrameRequest: URLRequest?

        init(viewModel: WebViewViewModel) {
            self.viewModel = viewModel
        }

        func observe(of webView: WKWebView) {
            lastMainFrameRequest = viewModel.request
            viewModel.bindNavigation(
                goBack: { [weak self, weak webView] in
                    guard let self, let webView,
                          let item = self.meaningfulBackItem(in: webView) else { return }
                    webView.go(to: item)
                },
                goForward: { [weak self, weak webView] in
                    guard let self, let webView,
                          let item = self.meaningfulForwardItem(in: webView) else { return }
                    webView.go(to: item)
                },
                retry: { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    webView.load(self.lastMainFrameRequest ?? self.viewModel.request)
                },
                navigate: { [weak self, weak webView] request in
                    self?.lastMainFrameRequest = request
                    self?.lastRequestedURL = request.url
                    webView?.load(request)
                }
            )

            progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) {
                [weak viewModel] _, change in
                guard let progress = change.newValue,
                      let viewModel else { return }
                Task { @MainActor [viewModel] in
                    viewModel.updateEstimatedProgress(progress)
                }
            }

            canGoBackObservation = webView.observe(\.canGoBack, options: [.initial, .new]) {
                [weak self] webView, _ in
                self?.publishNavigationState(from: webView)
            }
            canGoForwardObservation = webView.observe(\.canGoForward, options: [.initial, .new]) {
                [weak self] webView, _ in
                self?.publishNavigationState(from: webView)
            }
        }

        func stopObserving() {
            progressObservation?.invalidate()
            progressObservation = nil
            canGoBackObservation?.invalidate()
            canGoBackObservation = nil
            canGoForwardObservation?.invalidate()
            canGoForwardObservation = nil
            viewModel.unbindNavigation()
        }

        private func publishNavigationState(from webView: WKWebView) {
            let canGoBack = meaningfulBackItem(in: webView) != nil
            let canGoForward = meaningfulForwardItem(in: webView) != nil

            DispatchQueue.main.async { [weak viewModel] in
                viewModel?.updateNavigationState(
                    canGoBack: canGoBack,
                    canGoForward: canGoForward
                )
            }
        }

        private func meaningfulBackItem(in webView: WKWebView) -> WKBackForwardListItem? {
            meaningfulItem(
                in: webView.backForwardList.backList.reversed(),
                relativeTo: webView.url
            )
        }

        private func meaningfulForwardItem(in webView: WKWebView) -> WKBackForwardListItem? {
            meaningfulItem(
                in: webView.backForwardList.forwardList,
                relativeTo: webView.url
            )
        }

        private func meaningfulItem<S: Sequence>(
            in items: S,
            relativeTo currentURL: URL?
        ) -> WKBackForwardListItem? where S.Element == WKBackForwardListItem {
            let currentDocumentURL = documentURL(from: currentURL)
            return items.first { documentURL(from: $0.url) != currentDocumentURL }
        }

        private func documentURL(from url: URL?) -> URL? {
            guard let url,
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return url
            }
            components.fragment = nil
            return components.url
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

            if navigationAction.shouldPerformDownload {
                decisionHandler(.download)
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

            if navigationAction.targetFrame?.isMainFrame == true {
                lastMainFrameRequest = navigationAction.request
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
        ) {
            let contentDisposition = (navigationResponse.response as? HTTPURLResponse)?
                .value(forHTTPHeaderField: "Content-Disposition")?
                .lowercased()
            let isAttachment = contentDisposition?.contains("attachment") == true

            if navigationResponse.isForMainFrame,
               let response = navigationResponse.response as? HTTPURLResponse,
               response.statusCode >= 400 {
                viewModel.navigationDidReceiveHTTPError(statusCode: response.statusCode)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(
                !navigationResponse.canShowMIMEType || isAttachment ? .download : .allow
            )
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
            viewModel.navigationDidStart(url: webView.url)
        }

        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation?) {
            viewModel.navigationDidRedirect(url: webView.url)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
            disableDragInteractions(in: webView)
            publishNavigationState(from: webView)
            viewModel.navigationDidFinish(url: webView.url)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
            viewModel.navigationDidFail(url: webView.url, error: error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
            viewModel.navigationDidFail(url: webView.url, error: error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            viewModel.webContentProcessDidTerminate()
        }

        func webView(
            _ webView: WKWebView,
            didReceive challenge: URLAuthenticationChallenge,
            completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
        ) {
            completionHandler(.performDefaultHandling, nil)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard navigationAction.targetFrame == nil,
                  let url = navigationAction.request.url else {
                return nil
            }

            viewModel.trackPopup(url: url)
            let scheme = url.scheme?.lowercased()
            let internalSchemes = ["http", "https", "about", "data", "blob", "javascript"]
            if !internalSchemes.contains(scheme ?? "") || isExternalHost(url) {
                viewModel.trackExternalNavigation(url: url)
                viewModel.externalURLOpener.open(url)
                return nil
            }

            webView.load(navigationAction.request)
            return nil
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            let alert = UIAlertController(
                title: frame.request.url?.host ?? "CounterTestApp",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler()
            })

            guard let presenter = presentingViewController(for: webView) else {
                completionHandler()
                return
            }
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            let alert = UIAlertController(
                title: frame.request.url?.host ?? "CounterTestApp",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completionHandler(true)
            })

            guard let presenter = presentingViewController(for: webView) else {
                completionHandler(false)
                return
            }
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (String?) -> Void
        ) {
            let alert = UIAlertController(
                title: frame.request.url?.host ?? "CounterTestApp",
                message: prompt,
                preferredStyle: .alert
            )
            alert.addTextField { textField in
                textField.text = defaultText
            }
            alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel) { _ in
                completionHandler(nil)
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
                completionHandler(alert?.textFields?.first?.text)
            })

            guard let presenter = presentingViewController(for: webView) else {
                completionHandler(nil)
                return
            }
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            requestMediaCapturePermissionFor origin: WKSecurityOrigin,
            initiatedByFrame frame: WKFrameInfo,
            type: WKMediaCaptureType,
            decisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            Task { @MainActor [weak self] in
                guard let self else {
                    decisionHandler(.deny)
                    return
                }

                let granted = await requestMediaPermission(for: type)
                viewModel.trackMediaPermission(
                    type: mediaCaptureTypeName(type),
                    granted: granted
                )
                decisionHandler(granted ? .grant : .deny)
            }
        }

        @available(iOS 18.4, *)
        func webView(
            _ webView: WKWebView,
            runOpenPanelWith parameters: WKOpenPanelParameters,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping ([URL]?) -> Void
        ) {
            viewModel.documentPickerPresenter.presentFileImporter(
                allowsMultipleSelection: parameters.allowsMultipleSelection,
                completion: { [weak viewModel] urls in
                    viewModel?.trackFileImport(
                        filesCount: urls?.count,
                        cancelled: urls == nil
                    )
                    completionHandler(urls)
                }
            )
        }

        func webView(
            _ webView: WKWebView,
            navigationAction: WKNavigationAction,
            didBecome download: WKDownload
        ) {
            download.delegate = self
        }

        func webView(
            _ webView: WKWebView,
            navigationResponse: WKNavigationResponse,
            didBecome download: WKDownload
        ) {
            download.delegate = self
        }

        func download(
            _ download: WKDownload,
            decideDestinationUsing response: URLResponse,
            suggestedFilename: String,
            completionHandler: @escaping (URL?) -> Void
        ) {
            let safeFilename = sanitizedFilename(suggestedFilename)
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)

            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                let destination = directory.appendingPathComponent(safeFilename)
                downloadDestinations[ObjectIdentifier(download)] = destination
                viewModel.trackDownloadStarted(filename: safeFilename)
                completionHandler(destination)
            } catch {
                viewModel.trackDownloadFailed(error: error)
                completionHandler(nil)
            }
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let destination = downloadDestinations.removeValue(
                forKey: ObjectIdentifier(download)
            ) else { return }

            viewModel.trackDownloadFinished(filename: destination.lastPathComponent)
            viewModel.documentPickerPresenter.presentFileExporter(for: destination)
        }

        func download(
            _ download: WKDownload,
            didFailWithError error: Error,
            resumeData: Data?
        ) {
            if let destination = downloadDestinations.removeValue(
                forKey: ObjectIdentifier(download)
            ) {
                try? FileManager.default.removeItem(at: destination.deletingLastPathComponent())
            }
            viewModel.trackDownloadFailed(error: error)
        }

        private func isExternalHost(_ url: URL) -> Bool {
            guard let initialHost = viewModel.request.url?.host?.lowercased(),
                  let destinationHost = url.host?.lowercased() else {
                return false
            }

            return siteDomain(for: destinationHost) != siteDomain(for: initialHost)
        }

        /// Treats sibling subdomains as part of one web product. For example,
        /// `lk.nsq.market` and `www.nsq.market` both resolve to `nsq.market`.
        private func siteDomain(for host: String) -> String {
            let components = host.split(separator: ".")
            guard components.count >= 2,
                  !host.allSatisfy({ $0.isNumber || $0 == "." }) else {
                return host
            }

            return components.suffix(2).joined(separator: ".")
        }

        private func presentingViewController(for webView: WKWebView) -> UIViewController? {
            var responder: UIResponder? = webView
            while let currentResponder = responder {
                if let viewController = currentResponder as? UIViewController {
                    return topPresentedViewController(from: viewController)
                }
                responder = currentResponder.next
            }
            return nil
        }

        private func topPresentedViewController(from viewController: UIViewController) -> UIViewController {
            if let presented = viewController.presentedViewController {
                return topPresentedViewController(from: presented)
            }
            if let navigationController = viewController as? UINavigationController,
               let visibleViewController = navigationController.visibleViewController {
                return topPresentedViewController(from: visibleViewController)
            }
            if let tabBarController = viewController as? UITabBarController,
               let selectedViewController = tabBarController.selectedViewController {
                return topPresentedViewController(from: selectedViewController)
            }
            return viewController
        }

        private func requestMediaPermission(for type: WKMediaCaptureType) async -> Bool {
            switch type {
            case .camera:
                return await requestAccess(for: .video)
            case .microphone:
                return await requestAccess(for: .audio)
            case .cameraAndMicrophone:
                async let cameraAccess = requestAccess(for: .video)
                async let microphoneAccess = requestAccess(for: .audio)
                let cameraGranted = await cameraAccess
                let microphoneGranted = await microphoneAccess
                return cameraGranted && microphoneGranted
            @unknown default:
                return false
            }
        }

        private func requestAccess(for mediaType: AVMediaType) async -> Bool {
            switch AVCaptureDevice.authorizationStatus(for: mediaType) {
            case .authorized:
                return true
            case .notDetermined:
                return await withCheckedContinuation { continuation in
                    AVCaptureDevice.requestAccess(for: mediaType) { granted in
                        continuation.resume(returning: granted)
                    }
                }
            case .denied, .restricted:
                return false
            @unknown default:
                return false
            }
        }

        private func mediaCaptureTypeName(_ type: WKMediaCaptureType) -> String {
            switch type {
            case .camera:
                return "camera"
            case .microphone:
                return "microphone"
            case .cameraAndMicrophone:
                return "cameraAndMicrophone"
            @unknown default:
                return "unknown"
            }
        }

        private func sanitizedFilename(_ filename: String) -> String {
            let sanitized = filename
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
            return sanitized.isEmpty ? "download" : sanitized
        }

        func disableDragInteractions(in webView: WKWebView) {
            disableDragInteractions(in: webView.scrollView)
            DispatchQueue.main.async { [weak self, weak webView] in
                guard let self, let webView else { return }
                disableDragInteractions(in: webView.scrollView)
            }
        }

        private func disableDragInteractions(in view: UIView) {
            view.interactions
                .compactMap { $0 as? UIDragInteraction }
                .forEach { $0.isEnabled = false }
            view.subviews.forEach(disableDragInteractions(in:))
        }
    }
}
