public import SwiftUI

/// A button that copies a zip of a day's logs, ready to paste into a message, and that can be
/// dragged to drop the zip somewhere instead.
///
/// ```swift
/// if let today = LogFolder.current.today() {
///     ShareLogsButton(day: today)
/// }
/// ```
///
/// It reads "Copy Logs", then "Zipping…" while it makes the zip off the main thread, then
/// "Copied" for a couple of seconds.
public struct ShareLogsButton: View {
    enum Phase: Equatable {
        case idle, zipping, copied, failed
    }

    let day: LogDay
    @State private var phase = Phase.idle

    /// - Parameter day: The day whose logs it shares.
    public init(day: LogDay) {
        self.day = day
    }

    public var body: some View {
        Button(action: copy) {
            Label(title, systemImage: systemImage)
        }
        .disabled(phase == .zipping)
        .help("Click to copy a zip of these logs to paste into a message, or drag it to where you want it")
        .draggable(day) {
            Image(systemName: "doc.zipper")
                .font(.largeTitle)
                .padding()
        }
    }

    var title: LocalizedStringKey {
        switch phase {
        case .idle: "Copy Logs"
        case .zipping: "Zipping…"
        case .copied: "Copied"
        case .failed: "Couldn't Zip Logs"
        }
    }

    var systemImage: String {
        switch phase {
        case .idle, .zipping: "doc.zipper"
        case .copied: "checkmark"
        case .failed: "exclamationmark.triangle"
        }
    }

    private func copy() {
        phase = .zipping

        Task {
            do {
                let archive = try await Self.makeArchive(of: day)
                LogDay.copy(archive, to: .general)
                phase = .copied
            } catch {
                phase = .failed
            }

            try? await Task.sleep(for: .seconds(2))
            phase = .idle
        }
    }

    /// Zips the logs off the main thread, since `ditto` blocks until it's done.
    @concurrent private static func makeArchive(of day: LogDay) async throws -> URL {
        try day.makeArchive()
    }
}
