# CounterTestApp

An iOS 15+ SwiftUI application built with Coordinator + MVVM.

## Initial routing strategy

The app uses a mock remote-config strategy. `MockRemoteConfigRoutingService`
simulates an asynchronous configuration request and alternates the resulting
`LaunchDestination` on every successful cold launch. The last destination is
persisted through `StorageService` under a dedicated routing key.

During resolution, `SplashView` displays a branded loading screen. Once the
mock configuration is received, `SplashViewModel` passes the destination to
`AppCoordinator`, which switches to the selected flow.

With clean storage, the first launch opens `.counter`; subsequent launches open
`.webView`, `.counter`, `.webView`, and so on. Clearing the app's data resets
the sequence. `firstDestination` can be changed in `CounterTestAppApp.swift`.

## Storage strategy

`CounterViewModel` depends only on the `StorageService` abstraction. The project
contains interchangeable `UserDefaultsStorage` and `KeychainStorage`
implementations, both supporting any `Codable` value. The composition root uses
`UserDefaultsStorage` for the best score, as required by the Counter flow.

To demonstrate a different persistence backend, replace
`UserDefaultsStorage()` with `KeychainStorage()` in `CounterTestAppApp.swift`.
No Counter feature code needs to change.

## WebView foundation

`WebViewContainer` wraps `WKWebView` with `UIViewRepresentable`. Its
configuration is supplied through `WebViewConfigurationProviding`, keeping the
container testable and open to future configuration variants.

The default configuration enables JavaScript, JavaScript-created windows and a
custom application component in the user agent. It uses
`WKWebsiteDataStore.default()`, so cookies, cache and local storage persist
between WebView and app launches. The initial URL is
`https://lk.nsq.market/en/tools/testing`.

Navigation delegates, external URL handling, downloads, permissions, progress
and offline UI intentionally belong to the subsequent development steps.
