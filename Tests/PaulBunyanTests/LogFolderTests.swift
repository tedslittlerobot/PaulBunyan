import Foundation
import Testing

@testable import PaulBunyan

@Suite struct `LogFolder names` {
    @Test func `uses the name the Info.plist gives, as it is`() throws {
        let host = try TemporaryBundle(info: [LogFolder.infoPlistKey: "MyApp", "CFBundleName": "My App Menu Bar"])

        #expect(LogFolder.name(for: host.bundle) == "MyApp")
    }

    @Test func `falls back to the bundle's name, lowercased with hyphens for spaces`() throws {
        let host = try TemporaryBundle(info: ["CFBundleName": "Database Access Nexus"])

        #expect(LogFolder.name(for: host.bundle) == "database-access-nexus")
    }

    @Test func `falls back to the executable's name when the bundle has no name`() throws {
        let host = try TemporaryBundle(info: ["CFBundleExecutable": "Menu Bar Helper"])

        #expect(LogFolder.name(for: host.bundle) == "menu-bar-helper")
    }

    @Test func `is app when the bundle has no name at all`() throws {
        let host = try TemporaryBundle()

        #expect(LogFolder.name(for: host.bundle) == "app")
    }

    @Test func `skips an Info.plist name with nothing usable in it`() throws {
        let host = try TemporaryBundle(info: [LogFolder.infoPlistKey: " / ", "CFBundleName": "DAN"])

        #expect(LogFolder.name(for: host.bundle) == "dan")
    }

    @Test func `ignores an Info.plist name that isn't a string`() throws {
        let host = try TemporaryBundle(info: [LogFolder.infoPlistKey: 42, "CFBundleName": "DAN"])

        #expect(LogFolder.name(for: host.bundle) == "dan")
    }

    @Test(arguments: [
        ("my-app", "my-app"),
        ("../../etc", "etc"),
        ("my logs/today", "my-logs-today"),
        ("  dan  ", "dan"),
        ("dan.menu_bar-2", "dan.menu_bar-2"),
        ("café", "caf"),
        ("...", nil),
        ("", nil),
    ])
    func `is always one folder`(text: String, name: String?) {
        #expect(LogFolder.folderName(from: text) == name)
    }

    @Test func `makes a given name safe too`() throws {
        let home = try TemporaryDirectory()

        #expect(LogFolder(name: "../secrets", home: home.url).name == "secrets")
        #expect(LogFolder(name: "/", home: home.url).name == "app")
    }
}

@Suite struct `LogFolder locations` {
    @Test func `is in the home folder's .logs`() throws {
        let home = try TemporaryDirectory()
        let folder = LogFolder(name: "my-app", home: home.url)

        #expect(folder.url == home.url.appending(path: ".logs/my-app", directoryHint: .isDirectory))
    }

    @Test func `has a folder for each day, named by date`() throws {
        let home = try TemporaryDirectory()
        let folder = LogFolder(name: "my-app", home: home.url)

        let day = folder.folder(for: .noon(on: "2026-11-06"))

        #expect(day == folder.url.appending(path: "2026-11-06", directoryHint: .isDirectory))
        #expect(!FileManager.default.fileExists(atPath: day.path), "Asking for it doesn't create it")
    }

    @Test func `keeps ten days unless told otherwise, and always at least one`() throws {
        let home = try TemporaryDirectory()

        #expect(LogFolder(name: "my-app", home: home.url).daysKept == 10)
        #expect(LogFolder(name: "my-app", home: home.url, daysKept: 3).daysKept == 3)
        #expect(LogFolder(name: "my-app", home: home.url, daysKept: 0).daysKept == 1)
    }

    @Test func `is the main bundle's folder in the user's home`() {
        #expect(LogFolder.current.name == LogFolder.name(for: .main))
        #expect(LogFolder.current.url.deletingLastPathComponent().lastPathComponent == ".logs")
    }
}

@Suite struct `LogFolder days` {
    @Test func `lists folders named by date, newest first, ignoring anything else`() throws {
        let home = try TemporaryDirectory()
        let folder = LogFolder(name: "my-app", home: home.url)
        for name in ["2026-11-04", "2026-11-06", "2026-10-31", "notes", "2026-11-6"] {
            try home.makeFolder(".logs/my-app/\(name)")
        }
        try home.write("", to: ".logs/my-app/.DS_Store")

        #expect(folder.days.map(\.url.lastPathComponent) == ["2026-11-06", "2026-11-04", "2026-10-31"])
        #expect(folder.days.allSatisfy { $0.folderName == "my-app" })
    }

    @Test func `is empty before anything has logged`() throws {
        let home = try TemporaryDirectory()

        #expect(LogFolder(name: "my-app", home: home.url).days.isEmpty)
    }

    @Test func `finds today's logs`() throws {
        let home = try TemporaryDirectory()
        let folder = LogFolder(name: "my-app", home: home.url)
        try home.makeFolder(".logs/my-app/2026-11-05")

        #expect(folder.today(now: .noon(on: "2026-11-06")) == nil)

        try home.makeFolder(".logs/my-app/2026-11-06")
        #expect(folder.today(now: .noon(on: "2026-11-06"))?.url.lastPathComponent == "2026-11-06")
    }

    @Test func `removes all but the newest days, leaving anything else alone`() throws {
        let home = try TemporaryDirectory()
        let folder = LogFolder(name: "my-app", home: home.url)
        for day in 1...12 {
            try home.makeFolder(".logs/my-app/2026-11-\(String(format: "%02d", day))")
        }
        try home.makeFolder(".logs/my-app/keep-me")

        folder.removeExpiredDays()

        #expect(folder.days.count == 10)
        #expect(folder.days.last?.url.lastPathComponent == "2026-11-03")
        #expect(FileManager.default.fileExists(atPath: folder.url.appending(path: "keep-me").path))
    }

    @Test func `removes nothing when there are fewer days than it keeps`() throws {
        let home = try TemporaryDirectory()
        let folder = LogFolder(name: "my-app", home: home.url, daysKept: 3)
        for day in ["2026-11-01", "2026-11-02"] {
            try home.makeFolder(".logs/my-app/\(day)")
        }

        folder.removeExpiredDays()

        #expect(folder.days.count == 2)
    }

    @Test func `keeps as many days as it's told to`() throws {
        let home = try TemporaryDirectory()
        let folder = LogFolder(name: "my-app", home: home.url, daysKept: 2)
        for day in ["2026-11-01", "2026-11-02", "2026-11-03"] {
            try home.makeFolder(".logs/my-app/\(day)")
        }

        folder.removeExpiredDays()

        #expect(folder.days.map(\.url.lastPathComponent) == ["2026-11-03", "2026-11-02"])
    }

    @Test func `removing days from a folder that isn't there does nothing`() throws {
        let home = try TemporaryDirectory()

        LogFolder(name: "my-app", home: home.url).removeExpiredDays()

        #expect(!FileManager.default.fileExists(atPath: home.url.appending(path: ".logs").path))
    }
}
