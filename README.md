# CounterTestApp

CounterTestApp is an iOS 15.6+ SwiftUI application that demonstrates two launch flows:

1. A native casino-themed Counter game.
2. An iGaming flow hosted in a production-ready `WKWebView` container.

The project uses Coordinator + MVVM, protocol-based dependency injection, persistent storage abstractions, WebKit delegates, local notifications, analytics logging, and a compact critical test suite.

## Requirements

- Xcode 26 or newer
- iOS 15.6+
- Swift 5
- Internet access for the production WebView flow

The project uses Swift Package Manager to resolve `KeychainAccess`.

## Getting started

1. Clone the repository.
2. Open `CounterTestApp.xcodeproj` in Xcode.
3. Wait for Swift Package Manager to resolve dependencies.
4. Select the `CounterTestApp` scheme and an iOS simulator or device.
5. Run with `Cmd+R`.

Command-line build:

```sh
xcodebuild build \
  -project CounterTestApp.xcodeproj \
  -scheme CounterTestApp \
  -destination 'generic/platform=iOS Simulator'
```

Camera, microphone, and local-notification permissions are requested only when the associated feature needs them.

## Architecture

The application follows Coordinator + MVVM with protocol-driven services:

```text
CounterTestAppApp (composition root)
└── AppCoordinator
    ├── SplashViewModel
    ├── CounterViewModel
    ├── WebViewViewModel
    └── Services
        ├── InitialRouteProviding
        ├── StorageService
        ├── AnalyticsServiceProtocol
        ├── WebViewConfigurationProviding
        ├── ExternalURLOpening
        ├── DocumentPickerPresenting
        ├── NetworkMonitoring
        └── NotificationServiceProtocol
```

Responsibilities:

- `CounterTestAppApp` creates concrete dependencies and contains no feature logic.
- `AppCoordinator` owns the active `.counter` or `.webView` route and handles notification deep links.
- Views render state and forward user actions.
- View models contain presentation and feature state.
- Services isolate storage, routing, analytics, WebKit configuration, network monitoring, external URLs, document pickers, and notifications.

Long-lived callbacks use weak captures. KVO observations are invalidated when the WebView is dismantled, WebKit delegates are cleared, async Splash tasks are cancelled, and navigation closures are unbound to avoid retain cycles.

## Launch routing strategy

`MockRemoteConfigRoutingService` simulates a remote-config request. The last successful destination is persisted through `StorageService`, and every cold launch alternates:

```text
counter → webView → counter → webView → …
```

With empty storage, `firstDestination` controls the first flow and defaults to `.counter`. The simulated delay is configured through `loadingDelayNanoseconds`.

The routing strategy can be replaced through the `InitialRouteProviding` protocol without changing the coordinator or UI.

## Splash and progress

A single opaque `SplashView` is layered above `AppCoordinatorView` during startup.

- The mock configuration stage maps to 0–35%.
- For Counter, Splash completes after route resolution.
- For WebView, KVO-observed `WKWebView.estimatedProgress` maps to 35–100%.
- After the initial WebView finishes, Splash remains visible for one additional second.
- Later WebView navigations use a linear SwiftUI `ProgressView` at the top of the page.

No opacity transition is applied to Splash.

## Counter flow

The Counter module provides increment, decrement, reset, best-score persistence, animations, and accessibility identifiers.

`CounterViewModel` depends on `StorageService`, not on a concrete persistence API. Two implementations demonstrate SOLID dependency inversion:

- `UserDefaultsStorage` — used by the composition root.
- `KeychainStorage` — interchangeable secure persistence backed by `KeychainAccess`.

The counter never falls below zero. A new best score is persisted immediately.

## WebView configuration

`WebViewContainer` wraps `WKWebView` with `UIViewRepresentable`. `DefaultWebViewConfigurationProvider` configures:

- persistent `WKWebsiteDataStore.default()`;
- JavaScript execution;
- JavaScript-created windows;
- persistent cookies, cache, and local storage;
- a custom application component in the user agent;
- viewport rules that prevent page and input-focus zoom;
- disabled text selection, callouts, magnifier behavior, and link previews.

The scroll view has bounce and pinch zoom disabled.

The production URL is:

```text
https://lk.nsq.market/en/tools/testing
```

### Site-specific DOM customization

An idempotent `WKUserScript` is injected at `atDocumentEnd` into all frames. General interaction rules prevent viewport zoom, text selection, callouts, context menus, and drag-and-drop. Custom branding is guarded by an exact `nsq.market`/subdomain hostname check, so it is never applied to external pages.

For the testing page, the script:

- renames the `App testing` heading to `WhiteOut` and makes it bold;
- replaces the gray `#333333` page color with the Counter game's deep violet `#47147A`, while preserving the site's repeating translucent `bg.png` pattern;
- changes the Bootstrap accent text in `.col.col-12.col-lg-4` to the Counter game's gold `#FFBF2E` without changing its background;
- hides the non-functional mobile `#sidebarMenu` toggle;
- replaces the specific test YouTube embed (`5NV6Rdv1a3I`) with Michael Jackson's `Smooth Criminal` embed (`h_D3VFfhvs4`);
- replaces the test OGG audio URL with Wikimedia's corresponding MP3 transcode and reloads its `<audio>` element for iOS compatibility.

A `MutationObserver` reapplies these transformations when the site renders content dynamically. Every mutation is conditional, so already-customized elements are not rewritten repeatedly. These selectors and media IDs intentionally target this testing page and should be reviewed if its upstream markup changes.

## WebView navigation policy

`WKNavigationDelegate` handles action and response policies, lifecycle callbacks, redirects, authentication challenges, HTTP errors, downloads, and WebContent process termination.

- Same-site HTTP/HTTPS pages remain inside the WebView.
- Sibling subdomains such as `lk.nsq.market` and `www.nsq.market` are treated as the same site.
- Explicit cross-site links open through `UIApplication.shared.open`.
- Custom schemes such as `tel:`, `mailto:`, and `tg:` are handed to the system.
- Server redirects remain transparent inside WebView so authentication and payment redirects are not interrupted.
- Internal `target="_blank"` popups load in the current WebView.
- External popups open through the system.
- JavaScript `alert`, `confirm`, and `prompt` use native iOS dialogs.

The dark navigation bar observes meaningful `WKBackForwardList` state. Fragment-only history entries are ignored so Back and Forward do not merely scroll between anchors.

## Files, camera, and downloads

- Camera and microphone requests are mapped to `AVCaptureDevice` authorization and resolved through `WKPermissionDecision`.
- Required camera and microphone descriptions are present in the generated Info.plist.
- On iOS 18.4+, the public WebKit open-panel callback uses `UIDocumentPickerViewController` explicitly.
- Earlier supported iOS versions use WKWebView's native Safari-compatible file-input picker because the public open-panel callback is unavailable there.
- `WKDownloadDelegate` detects attachments and unsupported MIME types, downloads to an isolated temporary directory, and presents a document exporter.
- Temporary download files are removed after export cancellation, completion, or failure.

## Offline and error handling

`NWPathMonitor` publishes connectivity changes through the `NetworkMonitoring` abstraction.

- Offline state is displayed immediately, without waiting for a WebKit timeout.
- Navigation failures, HTTP 4xx/5xx responses, and WebContent termination have dedicated error states.
- Expected cancellation and policy-change errors are ignored.
- Retry reloads the last main-frame request.
- Retry is disabled until connectivity returns.

## Local notifications

`NotificationService` wraps `UNUserNotificationCenter` and acts as its delegate.

- Notification permission is requested after app startup.
- Entering inactive/background state schedules one notification after 10 seconds.
- Returning to active state cancels a pending reminder.
- A stable request identifier prevents duplicate notifications.
- Tapping the notification dismisses Splash, selects the WebView route, and loads:

```text
https://www.apple.com/
```

This is a local-notification implementation; APNs and a backend are not required.

## Analytics and logging

Features depend on `AnalyticsServiceProtocol`. The default `ConsoleAnalyticsService` uses unified logging (`OSLog`) and emits deterministic event names with sorted parameters.

Key event groups include:

- app startup, scene phase, route resolution, and route presentation;
- Splash start, success, and failure;
- Counter start, increment, decrement, reset, and new best score;
- WebView open, load lifecycle, redirects, cancellation, HTTP/network errors, retry, Back/Forward, deep links, and process termination;
- external URLs, popups, media permissions, file import, and downloads;
- network status changes;
- notification permission, scheduling, cancellation, response, and destination opening.

Production analytics can replace `ConsoleAnalyticsService` without changing feature code.

## Tests

The suite intentionally covers only critical behavior.

Unit tests verify:

- alternating launch routing;
- Counter persistence and the zero lower bound;
- WebView error and retry state.

UI smoke tests verify:

- starting the Counter game and incrementing its value;
- presence of WebView Back and Forward controls.

UI tests launch with `--ui-testing` and either `--force-counter` or `--force-webview`. Test mode uses local HTML, an always-connected network monitor, and a no-op notification service, so tests do not depend on internet access or permission dialogs.

Run from Xcode with `Product > Test`, or:

```sh
xcodebuild test \
  -project CounterTestApp.xcodeproj \
  -scheme CounterTestApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Project structure

```text
CounterTestApp/
├── Core/
│   ├── Analytics/
│   ├── Navigation/
│   ├── Notifications/
│   ├── Routing/
│   └── Storage/
├── Features/
│   ├── Counter/
│   ├── Splash/
│   └── WebView/
├── Assets.xcassets/
└── Launch Screen.storyboard
CounterTestAppTests/
└── CriticalUnitTests.swift
CounterTestAppUITests/
└── CriticalFlowUITests.swift
```

## Security and privacy notes

- Only HTTPS production URLs are configured.
- Cookies and local storage persist because iGaming sessions require continuity.
- Camera and microphone access is requested on demand.
- Custom schemes are delegated to iOS instead of loaded by WebKit.
- Download filenames are sanitized and files are stored in unique temporary directories.
- Analytics currently logs URLs and filenames for demonstration; production builds should apply the product's privacy and redaction policy.
