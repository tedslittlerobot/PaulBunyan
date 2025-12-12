import Foundation
import XCGLogger

class LogDestinationFactory {
    let name: String

    init(name: String) {
        self.name = name
    }

    var allDestinations: [any DestinationProtocol] {
        [nsLogDestination, rotatedFileDestination]
    }

    var nsLogDestination: any DestinationProtocol {
        let destination = AppleSystemLogDestination(identifier: "\(name).nslog")

        destination.outputLevel = .debug
        destination.showLogIdentifier = true
        destination.showFunctionName = true
        destination.showThreadName = false
        destination.showLevel = true
        destination.showFileName = true
        destination.showLineNumber = true
        destination.showDate = true
        destination.formatters = [XcodeFormatter(identifier: name)]

        return destination
    }

    var rotatedFileDestination: any DestinationProtocol {
        let destination = FileDestination(
            writeToFile: LogDirectoryJanitor.shared.prepareAndGetLogDirectory()
                .appendingPathComponent("\(name).log"),
            identifier: "\(name).file",
            shouldAppend: true,
            appendMarker: "\n\n----------========== RELAUNCH ==========----------\n\n",
        )

        destination.outputLevel = .debug
        destination.showLogIdentifier = false
        destination.showFunctionName = true
        destination.showThreadName = false
        destination.showLevel = true
        destination.showFileName = true
        destination.showLineNumber = true
        destination.showDate = true

        destination.logQueue = XCGLogger.logQueue

        return destination
    }
}
