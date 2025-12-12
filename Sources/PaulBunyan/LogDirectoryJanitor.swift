import Foundation

public struct LogDirectoryJanitor: Sendable {
    public static let shared = LogDirectoryJanitor()

    /// This is the logs directory for the application
    public let baseDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".logs/dan")

    public func getLogDirectoryFor(date: Date) -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return baseDirectory.appendingPathComponent("\(formatter.string(from: date))")
    }

    public func prepareAndGetLogDirectory(date: Date = Date()) -> URL {
        let directory = getLogDirectoryFor(date: date)

        try! ensureDirectoryExists(directory: directory)
        rotateOutOldDirectories(directory: baseDirectory)

        return directory
    }

    public func rotateOutOldDirectories(directory: URL) {
        Rotator(inDirectory: directory, keeping: 10)
            .deleteExpiredItems(inDirectory: directory)
    }

    public func ensureDirectoryExists(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public var logClusters: [LogCluster] {
        if !FileManager.default.fileExists(atPath: baseDirectory.path) {
            return []
        }

        return try! FileManager.default.contentsOfDirectory(
            at: baseDirectory, includingPropertiesForKeys: [.isDirectoryKey]
        )
        .filter {
            LogCluster.formatter.date(from: $0.lastPathComponent) != nil
        }.map { LogCluster(url: $0) }
        .sortedByDate
    }
}
