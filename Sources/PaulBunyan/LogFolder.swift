public import Foundation
public import XCGLogger

/// The folder an app keeps its logs in, `~/.logs/<name>`, with a folder for each day.
///
/// Each app gets its own folder, named in its `Info.plist` (``infoPlistKey``), so every logger
/// it makes logs to the same place without being told where:
///
/// ```swift
/// import PaulBunyan
///
/// let logger = LogFolder.current.makeLogger(named: "installer")
/// logger.info("Installing Homebrew")   // ~/.logs/my-app/2026-11-06/installer.log
/// ```
///
/// A helper app inside another app (a menu bar app, say) sets the same ``infoPlistKey`` as its
/// host, so both log to one folder.
public struct LogFolder: Sendable, Hashable {
    /// The `Info.plist` key that names an app's log folder, such as `my-app`. Without it, the
    /// folder is named after the bundle (``name(for:)``).
    public static let infoPlistKey = "PaulBunyanLogFolderName"

    /// How many days' folders are kept unless a folder says otherwise.
    public static let defaultDaysKept = 10

    /// The main bundle's log folder, in the current user's home folder.
    public static let current = LogFolder(bundle: .main)

    /// The folder's name, such as `my-app`.
    public let name: String

    /// The folder: `~/.logs/<name>`.
    public let url: URL

    /// How many days' folders are kept. Older ones are deleted each time a logger is made.
    public let daysKept: Int

    /// A log folder with a given name.
    ///
    /// - Parameters:
    ///   - name: The folder's name, such as `my-app`. It's made safe to use as one folder's name
    ///     (``name(for:)``), and is `app` if nothing's left of it.
    ///   - home: The home folder it's in. Defaults to the current user's.
    ///   - daysKept: How many days' folders to keep. At least 1.
    public init(
        name: String,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        daysKept: Int = defaultDaysKept,
    ) {
        self.name = Self.folderName(from: name) ?? "app"
        url = home.appending(path: ".logs/\(self.name)", directoryHint: .isDirectory)
        self.daysKept = max(1, daysKept)
    }

    /// The log folder a bundle names (``name(for:)``).
    ///
    /// - Parameters:
    ///   - bundle: An app's bundle, usually `Bundle.main`.
    ///   - home: The home folder it's in. Defaults to the current user's.
    ///   - daysKept: How many days' folders to keep. At least 1.
    public init(
        bundle: Bundle,
        home: URL = FileManager.default.homeDirectoryForCurrentUser,
        daysKept: Int = defaultDaysKept,
    ) {
        self.init(name: Self.name(for: bundle), home: home, daysKept: daysKept)
    }

    /// The name of a bundle's log folder: the first of these that it has, lowercased with
    /// hyphens for spaces (so `DAN` is `dan`, and `My App` is `my-app`):
    ///
    /// 1. its ``infoPlistKey`` value (not lowercased);
    /// 2. its `CFBundleName`;
    /// 3. its executable's name.
    ///
    /// Characters other than letters, digits, `.`, `_` and `-` become hyphens, so the name is
    /// always a single folder. It's `app` if the bundle has none of them.
    public static func name(for bundle: Bundle) -> String {
        let configured = bundle.object(forInfoDictionaryKey: infoPlistKey) as? String
        let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        let executableName = bundle.executableURL?.lastPathComponent

        return folderName(from: configured) ?? folderName(from: bundleName?.lowercased())
            ?? folderName(from: executableName?.lowercased()) ?? "app"
    }

    /// `text` made safe as one folder's name, or `nil` if nothing's left of it.
    static func folderName(from text: String?) -> String? {
        guard let text else { return nil }

        let safe = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacing(/[^A-Za-z0-9._-]+/, with: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-."))

        return safe.isEmpty ? nil : safe
    }

    /// The folder for a day's logs, such as `~/.logs/my-app/2026-11-06`, named in the user's
    /// time zone. It may not exist yet.
    public func folder(for date: Date = Date()) -> URL {
        url.appending(path: LogDay.folderName(for: date), directoryHint: .isDirectory)
    }

    /// The days that have logs, newest first. Read from disk each time.
    public var days: [LogDay] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []

        return contents.compactMap { LogDay(url: $0, folderName: name) }.sorted { $0.date > $1.date }
    }

    /// Today's logs, if anything has logged today.
    public func today(now: Date = Date()) -> LogDay? {
        let folder = LogDay.folderName(for: now)
        return days.first { $0.url.lastPathComponent == folder }
    }

    /// Makes a logger that writes to the system log and to `<name>.log` in the day's folder.
    ///
    /// If the app has written to that file before, the logger appends to it, after a `RELAUNCH`
    /// marker. Its first lines describe the app (XCGLogger's `logAppDetails()`).
    ///
    /// Creates the day's folder, and deletes the oldest days beyond ``daysKept``. The logger is
    /// fully configured before it's returned; see the README for sharing it between threads.
    ///
    /// - Parameters:
    ///   - name: The logger's name, and its file's: `installer` writes `installer.log`.
    ///   - level: The least severe level it logs. Defaults to `.debug`.
    ///   - date: The day whose folder it writes to. Defaults to today. A logger keeps writing
    ///     to that day's file however long the app runs.
    public func makeLogger(named name: String, level: XCGLogger.Level = .debug, date: Date = Date()) -> XCGLogger {
        let directory = folder(for: date)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        removeExpiredDays()

        let logger = XCGLogger(identifier: name, includeDefaultDestinations: false)
        logger.add(destination: LogDestinations.systemLog(named: name, level: level))
        logger.add(destination: LogDestinations.file(named: name, in: directory, level: level))
        logger.logAppDetails()

        return logger
    }

    /// Deletes the oldest days' folders, keeping the newest ``daysKept``. Leaves anything that
    /// isn't a day's folder alone.
    public func removeExpiredDays() {
        for day in days.dropFirst(daysKept) {
            try? FileManager.default.removeItem(at: day.url)
        }
    }
}
