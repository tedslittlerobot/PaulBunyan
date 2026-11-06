// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PaulBunyan",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "PaulBunyan", targets: ["PaulBunyan"])
    ],
    dependencies: [
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.1.5")
    ],
    targets: [
        .target(name: "PaulBunyan", dependencies: [.XCGLogger], swiftSettings: .standard),
        .testTarget(name: "PaulBunyanTests", dependencies: ["PaulBunyan", .XCGLogger], swiftSettings: .standard),
    ],
    swiftLanguageModes: [.v6],
)

extension [SwiftSetting] {
    /// Upcoming language features every target opts into ahead of the Swift version that makes
    /// them the default.
    static var standard: Self {
        [
            // `any` must be written on existential types, so their cost is visible.
            .enableUpcomingFeature("ExistentialAny"),
            // Imports are internal unless marked `public import`, so dependencies don't leak
            // into the API by accident.
            .enableUpcomingFeature("InternalImportsByDefault"),
            // A file can only use members from modules it imports itself.
            .enableUpcomingFeature("MemberImportVisibility"),
            // Swift 6.2's approachable concurrency: nonisolated async functions run on the
            // caller's actor, and conformances can be inferred as isolated.
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
        ]
    }
}

// Named after the product it stands for, so it reads like the module name it is.
// swift-format-ignore: AlwaysUseLowerCamelCase
extension PackageDescription.Target.Dependency {
    static var XCGLogger: Self { .product(name: "XCGLogger", package: "XCGLogger") }
}
