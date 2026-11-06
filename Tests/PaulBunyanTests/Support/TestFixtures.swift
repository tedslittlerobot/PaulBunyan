import Foundation
import XCGLogger

/// A throwaway folder, standing in for a home folder, removed when it's released.
final class TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "PaulBunyanTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    /// Makes a folder, and its parents, inside this one.
    @discardableResult
    func makeFolder(_ path: String) throws -> URL {
        let folder = url.appending(path: path, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// Writes a text file inside this one, making its folders.
    @discardableResult
    func write(_ text: String, to path: String) throws -> URL {
        let file = url.appending(path: path)
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(),
            withIntermediateDirectories: true,
        )
        try text.write(to: file, atomically: true, encoding: .utf8)
        return file
    }
}

/// A throwaway app bundle holding an Info.plist, and an executable if it names one, removed when
/// it's released.
final class TemporaryBundle {
    let directory: TemporaryDirectory
    let bundle: Bundle

    /// - Parameter info: Merged over a unique `CFBundleIdentifier` and an app package type.
    init(info: [String: Any] = [:]) throws {
        directory = try TemporaryDirectory()
        let contents = try directory.makeFolder("Host.app/Contents")

        let plist = [
            "CFBundleIdentifier": "com.example.PaulBunyanTests.\(UUID().uuidString)", "CFBundlePackageType": "APPL",
        ]
        .merging(info) { _, new in new }
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: contents.appending(path: "Info.plist"))

        if let executable = info["CFBundleExecutable"] as? String {
            try directory.write("", to: "Host.app/Contents/MacOS/\(executable)")
        }

        bundle = Bundle(url: directory.url.appending(path: "Host.app"))!
    }
}

extension Date {
    /// Noon on a day (`yyyy-MM-dd`) in the current time zone, so it's in that day's folder
    /// wherever the tests run.
    static func noon(on day: String) -> Date {
        let start = try! Date.ISO8601FormatStyle(timeZone: .current).year().month().day().dateSeparator(.dash)
            .parse(day)
        return start.addingTimeInterval(12 * 60 * 60)
    }
}

extension URL {
    /// The file's text, once XCGLogger has written everything it was given.
    func loggedText() throws -> String {
        XCGLogger.logQueue.sync {}
        return try String(contentsOf: self, encoding: .utf8)
    }
}
