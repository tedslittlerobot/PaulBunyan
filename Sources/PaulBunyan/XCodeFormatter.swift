import Foundation
import XCGLogger

class XcodeFormatter: LogFormatterProtocol {
    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }

    func format(logDetails: inout LogDetails, message: inout String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        message =
            [
                tag([formatter.string(from: logDetails.date)]),
                tag(
                    [emojiFor(level: logDetails.level), logDetails.level.description],
                    separator: " "),
                tag([identifier]),
                tag([logDetails.functionName]),
            ].joined(separator: " ")
            + "\n\(tag([stripBasePath(from: logDetails.fileName), "\(logDetails.lineNumber)"]))\n\n\(logDetails.message)"

        return message
    }

    func stripBasePath(from string: String) -> String {
        string.replacing(#/^.*DatabaseAccessNexus\//#, with: "")
    }

    func tag(_ elements: [String?], separator: String = ":") -> String {
        return "[\(elements.filter { $0 != nil }.map { $0! }.joined(separator: separator))]"
    }

    func emojiFor(level: XCGLogger.Level) -> String? {
        switch level {
        case .verbose:
            return nil
        case .debug:
            return "👾"
        case .info:
            return "ℹ️"
        case .notice:
            return "📔"
        case .warning:
            return "⚠️"
        case .error:
            return "🔥"
        case .severe:
            return "🔥🔥"
        case .alert:
            return "🔥🔥🔥"
        case .emergency:
            return "🔥⚡️🔥⚡️"
        case .none:
            return nil
        }
    }

    var debugDescription: String = "A log formatter"
}
