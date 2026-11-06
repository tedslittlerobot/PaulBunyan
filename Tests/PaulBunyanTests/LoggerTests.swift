import Foundation
import Testing
import XCGLogger

@testable import PaulBunyan

@Suite struct `LogFolder loggers` {
    let home: TemporaryDirectory
    let folder: LogFolder
    let day = Date.noon(on: "2026-11-06")

    init() throws {
        home = try TemporaryDirectory()
        folder = LogFolder(name: "my-app", home: home.url)
    }

    var installerLog: URL {
        folder.folder(for: day).appending(path: "installer.log")
    }

    @Test func `are named after their file`() {
        let logger = folder.makeLogger(named: "installer", date: day)

        #expect(logger.identifier == "installer")
    }

    @Test func `write to a file named after them in the day's folder`() throws {
        let logger = folder.makeLogger(named: "installer", date: day)

        logger.info("Installing Homebrew")

        let text = try installerLog.loggedText()
        #expect(text.contains("Installing Homebrew"))
        #expect(text.contains("[Info]"))
        #expect(text.contains("LoggerTests.swift"), "Each line says where it was logged from")
    }

    @Test func `start with the app's details`() throws {
        _ = folder.makeLogger(named: "installer", date: day)

        #expect(try installerLog.loggedText().contains("XCGLogger Version"))
    }

    @Test func `log debug lines unless told otherwise`() throws {
        let logger = folder.makeLogger(named: "installer", date: day)

        logger.debug("Checking the PATH")

        #expect(try installerLog.loggedText().contains("Checking the PATH"))
    }

    @Test func `leave out lines less severe than their level`() throws {
        let logger = folder.makeLogger(named: "installer", level: .warning, date: day)

        logger.info("Installing Homebrew")
        logger.warning("Homebrew is slow")

        let text = try installerLog.loggedText()
        #expect(!text.contains("Installing Homebrew"))
        #expect(text.contains("Homebrew is slow"))
    }

    @Test func `each write to their own file`() throws {
        folder.makeLogger(named: "installer", date: day).info("From the installer")
        folder.makeLogger(named: "dependency.homebrew", date: day).info("From Homebrew")

        let homebrewLog = folder.folder(for: day).appending(path: "dependency.homebrew.log")
        #expect(try installerLog.loggedText().contains("From the installer"))
        #expect(try !installerLog.loggedText().contains("From Homebrew"))
        #expect(try homebrewLog.loggedText().contains("From Homebrew"))
    }

    @Test func `append to the file across launches, with a marker between them`() throws {
        folder.makeLogger(named: "installer", date: day).info("First launch")
        _ = try installerLog.loggedText()
        folder.makeLogger(named: "installer", date: day).info("Second launch")

        let text = try installerLog.loggedText()
        let first = try #require(text.range(of: "First launch"))
        let marker = try #require(text.range(of: "RELAUNCH"))
        let second = try #require(text.range(of: "Second launch"))
        #expect(first.upperBound < marker.lowerBound && marker.upperBound < second.lowerBound)
    }

    @Test func `create the day's folder, and the folders above it`() {
        _ = folder.makeLogger(named: "installer", date: day)

        #expect(folder.days.map(\.url.lastPathComponent) == ["2026-11-06"])
    }

    @Test func `remove days beyond those kept`() throws {
        let folder = LogFolder(name: "my-app", home: home.url, daysKept: 2)
        for old in ["2026-11-01", "2026-11-02", "2026-11-03"] {
            try home.makeFolder(".logs/my-app/\(old)")
        }

        _ = folder.makeLogger(named: "installer", date: day)

        #expect(folder.days.map(\.url.lastPathComponent) == ["2026-11-06", "2026-11-03"])
    }
}
