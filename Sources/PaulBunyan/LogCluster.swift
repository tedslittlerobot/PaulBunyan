import CoreTransferable
import SwiftUI
import ZipArchive

public struct LogCluster {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public let url: URL
    public let date: Date

    init(url: URL) {
        self.url = url
        self.date = Self.formatter.date(from: url.lastPathComponent)!
    }

    public var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    public var friendlyDate: String {
        let formatter = DateFormatter()

        formatter.timeStyle = .none
        formatter.dateStyle = .medium

        return formatter.string(from: date)
    }

    public func openInFinder() {
        NSWorkspace.shared.open(url)
    }

    public func makeArchive() -> URL {
        let destination = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads/dan.\(url.lastPathComponent).\(NSUserName()).zip")  // dan.2012-01-01.tcruise.zip

        print("Archiving \(url.path) to \(destination.path)")
        SSZipArchive.createZipFile(atPath: destination.path, withContentsOfDirectory: url.path)

        return destination
    }

    public func copyArchiveUrl() {
        print("Copying archive url")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(makeArchive().dataRepresentation, forType: .fileURL)
    }
}

extension LogCluster: Identifiable {
    public var id: URL { url }
}

extension [LogCluster] {
    public var sortedByDate: [LogCluster] {
        sorted { $0.date > $1.date }
    }

    public var forToday: LogCluster? {
        filter { $0.isToday }.first
    }
}

extension LogCluster: Transferable {
    static public var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .fileURL) {
            $0.makeArchive().dataRepresentation
        }
    }
}
