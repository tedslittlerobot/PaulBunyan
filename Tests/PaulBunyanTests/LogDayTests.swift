import AppKit
import CoreTransferable
import Foundation
import Testing
import UniformTypeIdentifiers

@testable import PaulBunyan

@Suite struct `LogDay dates` {
    @Test(arguments: ["2026-11-06", "1999-12-31"])
    func `is a day when its folder is named by date`(name: String) {
        #expect(LogDay(url: URL(filePath: "/tmp/\(name)"), folderName: "dan") != nil)
    }

    @Test(arguments: ["latest", "2026-11-6", "2026-11-06-old", "06-11-2026", "2026-13-01", ""])
    func `isn't a day when its folder isn't named by date`(name: String) {
        #expect(LogDay(url: URL(filePath: "/tmp/\(name)"), folderName: "dan") == nil)
    }

    @Test func `starts at the beginning of the day its folder names`() throws {
        let day = try #require(LogDay(url: URL(filePath: "/tmp/2026-11-06"), folderName: "dan"))

        #expect(day.date == Calendar.current.startOfDay(for: .noon(on: "2026-11-06")))
        #expect(LogDay.folderName(for: day.date) == "2026-11-06")
    }

    @Test func `knows whether it's today`() throws {
        let day = try #require(LogDay(url: URL(filePath: "/tmp/2026-11-06"), folderName: "dan"))

        #expect(day.isToday(now: .noon(on: "2026-11-06")))
        #expect(!day.isToday(now: .noon(on: "2026-11-07")))
        #expect(!day.isToday(now: .noon(on: "2026-11-05")))
    }

    @Test func `is identified by its folder`() throws {
        let day = try #require(LogDay(url: URL(filePath: "/tmp/2026-11-06"), folderName: "dan"))

        #expect(day.id == URL(filePath: "/tmp/2026-11-06"))
    }
}

@Suite struct `LogDay files` {
    @Test func `lists its log files by name`() throws {
        let home = try TemporaryDirectory()
        try home.write("", to: "2026-11-06/sparkler.log")
        try home.write("", to: "2026-11-06/installer.log")
        try home.write("", to: "2026-11-06/notes.txt")
        let day = try #require(LogDay(url: home.url.appending(path: "2026-11-06"), folderName: "dan"))

        #expect(day.logFiles.map(\.lastPathComponent) == ["installer.log", "sparkler.log"])
    }

    @Test func `has no log files once its folder is gone`() throws {
        let day = try #require(LogDay(url: URL(filePath: "/nonexistent/2026-11-06"), folderName: "dan"))

        #expect(day.logFiles.isEmpty)
    }
}

@Suite struct `LogDay archives` {
    @Test func `are named after the log folder, the day and the user`() throws {
        let day = try #require(LogDay(url: URL(filePath: "/tmp/2026-11-06"), folderName: "my-app"))

        #expect(day.archiveName == "my-app.2026-11-06.\(NSUserName()).zip")
    }

    @Test func `hold the day's folder and its logs`() throws {
        let home = try TemporaryDirectory()
        try home.write("Installing Homebrew", to: "logs/2026-11-06/installer.log")
        let day = try #require(LogDay(url: home.url.appending(path: "logs/2026-11-06"), folderName: "my-app"))

        let archive = try day.makeArchive(in: home.url.appending(path: "Downloads"))

        #expect(archive == home.url.appending(path: "Downloads/\(day.archiveName)"))
        let unzipped = try unzip(archive, in: home)
        let log = unzipped.appending(path: "2026-11-06/installer.log")
        #expect(try String(contentsOf: log, encoding: .utf8) == "Installing Homebrew")
    }

    @Test func `replace an older zip of the same day`() throws {
        let home = try TemporaryDirectory()
        try home.write("Fresh", to: "logs/2026-11-06/installer.log")
        let day = try #require(LogDay(url: home.url.appending(path: "logs/2026-11-06"), folderName: "my-app"))
        try home.write("stale", to: "Downloads/\(day.archiveName)")

        let archive = try day.makeArchive(in: home.url.appending(path: "Downloads"))

        let log = try unzip(archive, in: home).appending(path: "2026-11-06/installer.log")
        #expect(try String(contentsOf: log, encoding: .utf8) == "Fresh")
    }

    @Test func `can't be made once the day's folder is gone`() throws {
        let home = try TemporaryDirectory()
        let day = try #require(LogDay(url: home.url.appending(path: "2026-11-06"), folderName: "my-app"))

        let error = #expect(throws: LogDay.ArchiveError.self) {
            try day.makeArchive(in: home.url)
        }
        #expect(error?.errorDescription?.contains("ditto exited with status") == true)
    }

    @Test @MainActor func `can be copied, ready to paste`() throws {
        let home = try TemporaryDirectory()
        let folder = try home.makeFolder("2026-11-06")
        let day = try #require(LogDay(url: folder, folderName: "my-app"))
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }

        let archive = try day.copyArchive(to: pasteboard, in: home.url)

        let copied = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL]
        #expect(copied == [archive])
    }

    @Test func `are what a dragged day exports`() async throws {
        let home = try TemporaryDirectory()
        let folder = try home.makeFolder("logs/2026-11-06")
        let day = try #require(LogDay(url: folder, folderName: "paulbunyantests-\(UUID().uuidString)"))
        defer { try? FileManager.default.removeItem(at: URL.downloadsDirectory.appending(path: day.archiveName)) }

        let data = try await day.exported(as: .zip)

        #expect(data.starts(with: [0x50, 0x4B]), "It's a zip")
    }

    private func unzip(_ archive: URL, in home: TemporaryDirectory) throws -> URL {
        let destination = try home.makeFolder("unzipped-\(UUID().uuidString)")
        let ditto = try Process.run(
            URL(filePath: "/usr/bin/ditto"), arguments: ["-x", "-k", archive.path, destination.path])
        ditto.waitUntilExit()
        try #require(ditto.terminationStatus == 0)
        return destination
    }
}
