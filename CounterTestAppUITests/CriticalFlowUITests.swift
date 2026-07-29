import XCTest

final class CriticalFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCounterCanStartAndIncrement() {
        let app = launchApp(forcedRoute: "--force-counter")

        let startButton = app.buttons["counter.start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3))
        startButton.tap()

        let incrementButton = app.buttons["counter.increment"]
        XCTAssertTrue(incrementButton.waitForExistence(timeout: 3))
        incrementButton.tap()

        XCTAssertTrue(app.staticTexts["counter.value"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.staticTexts["counter.value"].label, "1")
    }

    func testWebViewShowsNavigationControls() {
        let app = launchApp(forcedRoute: "--force-webview")

        XCTAssertTrue(app.buttons["web.navigation.back"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["web.navigation.forward"].exists)
    }

    private func launchApp(forcedRoute: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", forcedRoute]
        app.launch()
        return app
    }
}
