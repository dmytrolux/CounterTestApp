import UserNotifications
import OSLog

@MainActor
protocol NotificationServiceProtocol: AnyObject {
    func configure(onNotificationOpened: @escaping (URL) -> Void)
    func requestAuthorization()
    func scheduleBackgroundNotification(after delay: TimeInterval)
    func cancelPendingBackgroundNotification()
}

@MainActor
final class NoopNotificationService: NotificationServiceProtocol {
    func configure(onNotificationOpened: @escaping (URL) -> Void) {}
    func requestAuthorization() {}
    func scheduleBackgroundNotification(after delay: TimeInterval) {}
    func cancelPendingBackgroundNotification() {}
}

@MainActor
final class NotificationService: NSObject, NotificationServiceProtocol {
    private enum Constants {
        static let requestIdentifier = "background-reminder"
        nonisolated static let destinationURLKey = "destination_url"
    }

    private let notificationCenter: UNUserNotificationCenter
    private let destinationURL: URL
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "CounterTestApp",
        category: "LocalNotifications"
    )
    private var onNotificationOpened: ((URL) -> Void)?

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        destinationURL: URL
    ) {
        self.notificationCenter = notificationCenter
        self.destinationURL = destinationURL
        super.init()
        notificationCenter.delegate = self
    }

    func configure(onNotificationOpened: @escaping (URL) -> Void) {
        self.onNotificationOpened = onNotificationOpened
    }

    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) {
            [weak self] granted, error in
            guard let self else { return }
            if let error {
                logger.error("Notification permission failed: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.info("Notification permission granted: \(granted, privacy: .public)")
            }
        }
    }

    func scheduleBackgroundNotification(after delay: TimeInterval) {
        addBackgroundNotification(after: delay)
    }

    private func addBackgroundNotification(after delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "CounterTestApp"
        content.body = "Come back and continue your experience."
        content.sound = .default
        content.userInfo = [Constants.destinationURLKey: destinationURL.absoluteString]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(delay, 1),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Constants.requestIdentifier,
            content: content,
            trigger: trigger
        )

        // Adding a request with the same identifier replaces the existing one.
        // Avoid remove+add here: those asynchronous operations can race while
        // the scene quickly transitions from inactive to background.
        notificationCenter.add(request) { [weak self] error in
            guard let self else { return }
            if let error {
                logger.error("Notification scheduling failed: \(error.localizedDescription, privacy: .public)")
            } else {
                logger.info("Background notification scheduled in \(delay, privacy: .public) seconds")
            }
        }
    }

    func cancelPendingBackgroundNotification() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [Constants.requestIdentifier]
        )
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let urlString = response.notification.request.content.userInfo[
            Constants.destinationURLKey
        ] as? String

        Task { @MainActor [weak self] in
            defer { completionHandler() }
            guard let self,
                  let urlString,
                  let url = URL(string: urlString) else { return }
            onNotificationOpened?(url)
        }
    }
}
