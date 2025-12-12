import Foundation

class Rotator {
    let items: [String]
    let itemsToKeep: Int

    init(_ items: [String], keeping: Int) {
        self.items = items
        self.itemsToKeep = keeping
    }

    init(inDirectory directory: URL, keeping: Int) {
        let results = try! FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isDirectoryKey]
        )
        .map { $0.lastPathComponent }

        self.items = results
        self.itemsToKeep = keeping
    }

    var sortedItems: [String] { items.sorted() }

    var lastItemToKeep: Int? {
        if itemsToKeep >= items.count {
            return nil
        }

        return max(0, items.count - itemsToKeep - 1)
    }

    var itemsToDelete: [String] {
        guard let lastItemToKeep else { return [] }

        return Array(sortedItems[0...lastItemToKeep])
    }

    func deleteExpiredItems(inDirectory directory: URL) {
        for item in itemsToDelete {
            try! FileManager.default.removeItem(at: directory.appendingPathComponent(item))
        }
    }
}
