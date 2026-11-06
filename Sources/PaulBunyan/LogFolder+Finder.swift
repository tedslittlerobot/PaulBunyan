import AppKit
import Foundation

extension LogFolder {
    /// Opens the folder in Finder, creating it first if nothing has logged yet.
    @MainActor public func showInFinder() {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }
}
