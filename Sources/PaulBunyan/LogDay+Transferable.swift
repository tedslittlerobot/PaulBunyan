public import CoreTransferable
import UniformTypeIdentifiers

extension LogDay: Transferable {
    /// A zip of the day's logs (``makeArchive(in:)``), made in the Downloads folder when it's
    /// dropped.
    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .zip) { day in
            SentTransferredFile(try day.makeArchive())
        }
    }
}
