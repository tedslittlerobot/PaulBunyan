import Foundation
import Testing
import XCGLogger

@testable import PaulBunyan

@Suite struct `LogLineFormatter lines` {
    @Test func `put the time, level, logger and function above the place and the message`() {
        let date = Date.noon(on: "2026-11-06").addingTimeInterval(5 * 60 + 9)

        let line = LogLineFormatter.line(
            date: date,
            level: .info,
            loggerName: "installer",
            function: "run()",
            file: "/src/Installer/InstallationModel.swift",
            line: 42,
            message: "Installing Homebrew",
        )

        #expect(line == "[12:05:09] [ℹ️ Info] [installer] [run()]\n[InstallationModel.swift:42]\n\nInstalling Homebrew")
    }

    @Test func `mark each level`() {
        #expect(LogLineFormatter.emoji(for: .debug) == "👾")
        #expect(LogLineFormatter.emoji(for: .info) == "ℹ️")
        #expect(LogLineFormatter.emoji(for: .notice) == "📔")
        #expect(LogLineFormatter.emoji(for: .warning) == "⚠️")
        #expect(LogLineFormatter.emoji(for: .error) == "🔥")
        #expect(LogLineFormatter.emoji(for: .severe) == "🔥🔥")
        #expect(LogLineFormatter.emoji(for: .alert) == "🔥🔥🔥")
        #expect(LogLineFormatter.emoji(for: .emergency) == "🔥⚡️🔥⚡️")
    }

    @Test func `leave verbose lines unmarked`() {
        #expect(LogLineFormatter.emoji(for: .verbose) == nil)
        #expect(LogLineFormatter.tag([nil, "Verbose"], separator: " ") == "[Verbose]")
    }

    @Test func `replace the message they're given`() {
        let formatter = LogLineFormatter(loggerName: "installer")
        var details = LogDetails(
            level: .warning,
            date: .noon(on: "2026-11-06"),
            message: "Homebrew is slow",
            functionName: "run()",
            fileName: "Installer.swift",
            lineNumber: 7,
        )
        var message = "Homebrew is slow"

        let formatted = formatter.format(logDetails: &details, message: &message)

        #expect(formatted == message)
        #expect(message.hasPrefix("[12:00:00] [⚠️ Warning] [installer] [run()]"))
        #expect(message.hasSuffix("[Installer.swift:7]\n\nHomebrew is slow"))
    }
}
