import Foundation
import OSLog

final class ConsoleAnalyticsService: AnalyticsServiceProtocol {
    private let logger: Logger

    init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "CounterTestApp",
        category: String = "Analytics"
    ) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    func track(event: String, parameters: [String: String]) {
        guard !parameters.isEmpty else {
            logger.info("Event: \(event, privacy: .public)")
            return
        }

        let metadata = parameters
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")

        logger.info("Event: \(event, privacy: .public), parameters: \(metadata, privacy: .public)")
    }
}
