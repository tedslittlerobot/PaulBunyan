import Foundation
import XCGLogger

/// The two places every logger writes to.
enum LogDestinations {
    /// Between launches of the app, a file gets this line, so each launch's lines stand apart.
    static let relaunchMarker = "\n\n----------========== RELAUNCH ==========----------\n\n"

    /// The system log, which Console.app shows, formatted by ``LogLineFormatter``.
    static func systemLog(named name: String, level: XCGLogger.Level) -> any DestinationProtocol {
        let destination = AppleSystemLogDestination(identifier: "\(name).nslog")
        destination.outputLevel = level
        destination.showLogIdentifier = true
        destination.showFunctionName = true
        destination.showThreadName = false
        destination.showLevel = true
        destination.showFileName = true
        destination.showLineNumber = true
        destination.showDate = true
        destination.formatters = [LogLineFormatter(loggerName: name)]
        return destination
    }

    /// `<name>.log` in `directory`, appended to.
    static func file(named name: String, in directory: URL, level: XCGLogger.Level) -> any DestinationProtocol {
        let destination = FileDestination(
            writeToFile: directory.appending(path: "\(name).log"),
            identifier: "\(name).file",
            shouldAppend: true,
            appendMarker: relaunchMarker,
        )
        destination.outputLevel = level
        destination.showLogIdentifier = false
        destination.showFunctionName = true
        destination.showThreadName = false
        destination.showLevel = true
        destination.showFileName = true
        destination.showLineNumber = true
        destination.showDate = true
        // XCGLogger's own serial queue, so writes to a file never overlap.
        destination.logQueue = XCGLogger.logQueue
        return destination
    }
}
