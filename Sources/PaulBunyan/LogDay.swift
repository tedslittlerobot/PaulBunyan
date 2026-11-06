public import AppKit
public import Foundation

/// One day's logs: a folder in a ``LogFolder``, such as `~/.logs/my-app/2026-11-06`, which can
/// be zipped to share.
///
/// ```swift
/// for day in LogFolder.current.days {
///     print(day.date, day.logFiles)
/// }
///
/// try LogFolder.current.today()?.copyArchive()   // zips today's logs, ready to paste
/// ```
///
/// It's `Transferable`, so dragging one (`.draggable(day)`) drops a zip of it.
public struct LogDay: Sendable, Hashable, Identifiable {
    /// Errors from zipping a day's logs.
    public enum ArchiveError: Error, LocalizedError, Equatable {
        /// `ditto` couldn't make the zip.
        case zipFailed(status: Int32, message: String)

        public var errorDescription: String? {
            switch self {
            case .zipFailed(let status, let message):
                "Couldn't zip the logs (ditto exited with status \(status)): \(message)"
            }
        }
    }

    /// The day's folder.
    public let url: URL

    /// The start of the day, in the time zone it was named in.
    public let date: Date

    /// The name of the ``LogFolder`` it's in, such as `my-app`, which names its archives.
    public let folderName: String

    /// The day's folder, which identifies it.
    public var id: URL { url }

    /// A day from its folder, or `nil` if the folder's name isn't a date (`2026-11-06`).
    ///
    /// - Parameters:
    ///   - url: The day's folder.
    ///   - folderName: The ``LogFolder``'s name.
    public init?(url: URL, folderName: String) {
        guard let date = Self.date(fromFolderName: url.lastPathComponent) else { return nil }

        self.url = url
        self.date = date
        self.folderName = folderName
    }

    /// Whether it's the current day in `calendar`.
    public func isToday(in calendar: Calendar = .current, now: Date = Date()) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }

    /// The day's log files, sorted by name. Read from disk each time.
    public var logFiles: [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []

        return contents.filter { $0.pathExtension == "log" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// The archive's file name, `<folder>.<day>.<user>.zip`, such as `my-app.2026-11-06.jdoe.zip`,
    /// so whoever receives it can tell where it came from.
    public var archiveName: String {
        "\(folderName).\(url.lastPathComponent).\(NSUserName()).zip"
    }

    /// Zips the day's folder into `directory`, replacing an older zip of the same day.
    ///
    /// The zip holds the day's folder (`2026-11-06/installer.log` and so on). It's made with
    /// `/usr/bin/ditto`, and blocks until it's done, so call it off the main thread for a
    /// large folder.
    ///
    /// - Parameter directory: Where to put the zip, which is created if it isn't there.
    ///   Defaults to the user's Downloads folder.
    /// - Returns: The zip.
    /// - Throws: ``ArchiveError/zipFailed(status:message:)`` if `ditto` can't make it, such as
    ///   when the day's folder is gone.
    public func makeArchive(in directory: URL = .downloadsDirectory) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let archive = directory.appending(path: archiveName)
        try? FileManager.default.removeItem(at: archive)

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent", url.path, archive.path]
        let errors = Pipe()
        process.standardError = errors

        try process.run()
        let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw ArchiveError.zipFailed(
                status: process.terminationStatus,
                message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            )
        }

        return archive
    }

    /// Zips the day's folder (``makeArchive(in:)``) and copies the zip, ready to paste into a
    /// message or a Finder window.
    ///
    /// - Parameters:
    ///   - pasteboard: Where to copy it. Defaults to the general pasteboard.
    ///   - directory: Where to put the zip. Defaults to the user's Downloads folder.
    /// - Returns: The zip.
    @MainActor @discardableResult
    public func copyArchive(to pasteboard: NSPasteboard = .general, in directory: URL = .downloadsDirectory) throws
        -> URL
    {
        let archive = try makeArchive(in: directory)
        Self.copy(archive, to: pasteboard)
        return archive
    }

    /// Opens the day's folder in Finder.
    @MainActor public func showInFinder() {
        NSWorkspace.shared.open(url)
    }

    /// Puts a file on the pasteboard, as Finder's Copy does.
    @MainActor static func copy(_ file: URL, to pasteboard: NSPasteboard) {
        pasteboard.clearContents()
        pasteboard.writeObjects([file as NSURL])
    }

    // MARK: Folder names

    /// `2026-11-06`, in the user's time zone.
    static let folderNameStyle = Date.ISO8601FormatStyle(timeZone: .current).year().month().day()
        .dateSeparator(.dash)

    static func folderName(for date: Date) -> String {
        date.formatted(folderNameStyle)
    }

    static func date(fromFolderName name: String) -> Date? {
        guard name.wholeMatch(of: /\d{4}-\d{2}-\d{2}/) != nil else { return nil }

        return try? folderNameStyle.parse(name)
    }
}
