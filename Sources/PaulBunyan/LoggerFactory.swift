import Foundation
import XCGLogger

public struct LoggerFactory: Sendable {
    public static let shared = LoggerFactory()

    public func create(named name: String) -> XCGLogger {
        let logger = XCGLogger(identifier: name, includeDefaultDestinations: false)

        LogDestinationFactory(name: name)
            .allDestinations
            .forEach { logger.add(destination: $0) }

        logger.logAppDetails()

        return logger
    }
}
