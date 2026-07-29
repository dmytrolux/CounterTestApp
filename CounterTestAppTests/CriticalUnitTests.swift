import XCTest
@testable import CounterTestApp

@MainActor
final class CriticalUnitTests: XCTestCase {
    func testRoutingAlternatesBetweenCounterAndWebView() async throws {
        let storage = InMemoryStorage()
        let service = MockRemoteConfigRoutingService(
            storage: storage,
            firstDestination: .counter,
            loadingDelayNanoseconds: 0
        )

        let first = try await service.fetchInitialDestination()
        let second = try await service.fetchInitialDestination()
        let third = try await service.fetchInitialDestination()

        XCTAssertEqual(first, .counter)
        XCTAssertEqual(second, .webView)
        XCTAssertEqual(third, .counter)
    }

    func testCounterPersistsNewBestScoreAndNeverGoesBelowZero() {
        let storage = InMemoryStorage()
        let viewModel = CounterViewModel(
            storage: storage,
            analyticsService: AnalyticsSpy()
        )

        viewModel.increment()
        viewModel.increment()
        viewModel.decrement()
        viewModel.decrement()
        viewModel.decrement()

        let persistedBestScore: Int? = storage.value(forKey: "counter.bestScore")
        XCTAssertEqual(viewModel.count, 0)
        XCTAssertEqual(viewModel.bestScore, 2)
        XCTAssertEqual(persistedBestScore, 2)
    }

    func testWebViewFailureShowsErrorAndRetryInvokesReload() {
        var didRetry = false
        let viewModel = makeWebViewModel()
        viewModel.bindNavigation(
            goBack: {},
            goForward: {},
            retry: { didRetry = true },
            navigate: { _ in }
        )

        viewModel.navigationDidFail(
            url: URL(string: "https://example.com"),
            error: URLError(.timedOut)
        )

        XCTAssertEqual(viewModel.loadError?.kind, .general)
        viewModel.retry()
        XCTAssertTrue(didRetry)
        XCTAssertTrue(viewModel.isRetrying)
    }

    private func makeWebViewModel() -> WebViewViewModel {
        WebViewViewModel(
            url: URL(string: "https://example.com")!,
            configurationProvider: DefaultWebViewConfigurationProvider(),
            externalURLOpener: ExternalURLOpenerSpy(),
            documentPickerPresenter: DocumentPickerPresenterSpy(),
            networkMonitor: NetworkMonitorStub(),
            analyticsService: AnalyticsSpy(),
            onProgressUpdated: { _ in },
            onInitialLoadFinished: {}
        )
    }
}

private final class InMemoryStorage: StorageService {
    private var values: [String: Any] = [:]

    func save(_ value: Any?, forKey key: String) {
        values[key] = value
    }

    func value<T>(forKey key: String) -> T? {
        values[key] as? T
    }

    func removeValue(forKey key: String) {
        values.removeValue(forKey: key)
    }
}

private final class AnalyticsSpy: AnalyticsServiceProtocol {
    func track(event: String, parameters: [String: String]) {}
}

@MainActor
private final class ExternalURLOpenerSpy: ExternalURLOpening {
    func open(_ url: URL) {}
}

@MainActor
private final class DocumentPickerPresenterSpy: DocumentPickerPresenting {
    func presentFileImporter(
        allowsMultipleSelection: Bool,
        completion: @escaping ([URL]?) -> Void
    ) {}

    func presentFileExporter(for fileURL: URL) {}
}

@MainActor
private final class NetworkMonitorStub: NetworkMonitoring {
    func start(statusDidChange: @escaping (Bool) -> Void) {}
    func stop() {}
}
