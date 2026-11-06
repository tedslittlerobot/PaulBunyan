import Foundation
import XCGLogger

/// Formats a system log line as `[time] [emoji level] [logger] [function]`, then the file and
/// line, then the message:
///
/// ```
/// [09:15:02] [ℹ️ Info] [installer] [run()]
/// [InstallationModel.swift:42]
///
/// Installing Homebrew
/// ```
///
/// It keeps no state between lines, so it's safe on any thread.
final class LogLineFormatter: LogFormatterProtocol, Sendable {
    let loggerName: String

    init(loggerName: String) {
        self.loggerName = loggerName
    }

    func format(logDetails: inout LogDetails, message: inout String) -> String {
        message = Self.line(
            date: logDetails.date,
            level: logDetails.level,
            loggerName: loggerName,
            function: logDetails.functionName,
            file: logDetails.fileName,
            line: logDetails.lineNumber,
            message: logDetails.message,
        )
        return message
    }

    static func line(
        date: Date,
        level: XCGLogger.Level,
        loggerName: String,
        function: String,
        file: String,
        line: Int,
        message: String,
    ) -> String {
        let time = date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits))
        let header = [
            tag([time]),
            tag([emoji(for: level), level.description], separator: " "),
            tag([loggerName]),
            tag([function]),
        ]
        .joined(separator: " ")

        return "\(header)\n\(tag([URL(filePath: file).lastPathComponent, "\(line)"]))\n\n\(message)"
    }

    /// `[a:b]`, leaving out missing parts.
    static func tag(_ parts: [String?], separator: String = ":") -> String {
        "[\(parts.compactMap(\.self).joined(separator: separator))]"
    }

    static func emoji(for level: XCGLogger.Level) -> String? {
        switch level {
        case .verbose, .none: nil
        case .debug: "👾"
        case .info: "ℹ️"
        case .notice: "📔"
        case .warning: "⚠️"
        case .error: "🔥"
        case .severe: "🔥🔥"
        case .alert: "🔥🔥🔥"
        case .emergency: "🔥⚡️🔥⚡️"
        }
    }

    var debugDescription: String { "PaulBunyan's log line formatter" }
}
