# CounterTestApp

An iOS 15+ SwiftUI application built with Coordinator + MVVM.

## Initial routing strategy

The app uses a mock remote-config strategy. `MockRemoteConfigRoutingService`
simulates an asynchronous configuration request and returns a configured
`LaunchDestination`. The composition root currently configures `.webView`.

During resolution, `SplashView` displays a branded loading screen. Once the
mock configuration is received, `SplashViewModel` passes the destination to
`AppCoordinator`, which switches to the selected flow. The Counter and WebView
destinations are placeholders until their dedicated development steps.

To select the Counter flow for local testing, change the injected destination
in `CounterTestAppApp.swift` from `.webView` to `.counter`.
