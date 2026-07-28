# CounterTestApp

An iOS 15+ SwiftUI application built with Coordinator + MVVM.

## Initial routing strategy

The app uses a mock remote-config strategy. `MockRemoteConfigRoutingService`
simulates an asynchronous configuration request and returns a configured
`LaunchDestination`. The composition root currently configures `.counter` so
the completed Counter module is shown after launch.

During resolution, `SplashView` displays a branded loading screen. Once the
mock configuration is received, `SplashViewModel` passes the destination to
`AppCoordinator`, which switches to the selected flow. The Counter and WebView
destinations are placeholders until their dedicated development steps.

To select the WebView flow for local testing, change the injected destination
in `CounterTestAppApp.swift` from `.counter` to `.webView`.

## Storage strategy

`CounterViewModel` depends only on the `StorageService` abstraction. The project
contains interchangeable `UserDefaultsStorage` and `KeychainStorage`
implementations, both supporting any `Codable` value. The composition root uses
`UserDefaultsStorage` for the best score, as required by the Counter flow.

To demonstrate a different persistence backend, replace
`UserDefaultsStorage()` with `KeychainStorage()` in `CounterTestAppApp.swift`.
No Counter feature code needs to change.
