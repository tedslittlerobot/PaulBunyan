public import XCGLogger

/// PaulBunyan 1.x's way to make a logger, which always logged to `~/.logs/dan`.
@available(*, deprecated, message: "Use LogFolder.current.makeLogger(named:), which logs to the app's own folder")
public struct LoggerFactory: Sendable {
    /// The factory.
    public static let shared = LoggerFactory()

    /// Makes a logger in the app's log folder (``LogFolder/current``).
    public func create(named name: String) -> XCGLogger {
        LogFolder.current.makeLogger(named: name)
    }
}
