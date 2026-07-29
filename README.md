# CounterTestApp

An iOS 15+ SwiftUI application built with Coordinator + MVVM.

## Initial routing strategy

The app uses a mock remote-config strategy. `MockRemoteConfigRoutingService`
simulates an asynchronous configuration request and alternates the resulting
`LaunchDestination` on every successful cold launch. The last destination is
persisted through `StorageService` under a dedicated routing key.

`AppCoordinatorView` contains only the `.counter` and `.webView` destinations.
A single `SplashView` is always layered above the selected destination while
the launch pipeline is running. During the mock configuration delay its
progress advances from 0% to 35%.

For `.counter`, progress completes and the splash is removed immediately after
route resolution. For `.webView`, the live WebView is created underneath the
splash and its KVO `estimatedProgress` is mapped from 35% to 100%. The splash
then remains visible until `WKNavigationDelegate.didFinish` plus one second.

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

`estimatedProgress` is observed through KVO by the shared launch splash while
the live WebView loads underneath. The splash is dismissed one second after
`WKNavigationDelegate.webView(_:didFinish:)`, rather than immediately at 100%,
so cold WebKit process startup and final rendering are hidden from the user.

The navigation delegate transparently allows redirects, reports navigation
lifecycle analytics and keeps ordinary navigation inside the WebView. Explicit
links to another HTTP(S) host open in the system browser. Custom schemes such
as `tel:`, `mailto:` and `tg:` are passed to `UIApplication`.

Downloads, camera permissions, popup creation, offline UI and navigation
controls intentionally belong to the subsequent development steps.
