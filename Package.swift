// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PaulBunyan",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PaulBunyan",
            targets: ["PaulBunyan"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.6.0"),
        .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.1.5"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PaulBunyan",
            dependencies: [.XCGLogger, .ZipArchive],
        ),
        .testTarget(
            name: "PaulBunyanTests",
            dependencies: ["PaulBunyan"]
        ),
    ]
)

extension PackageDescription.Target.Dependency {
    static var XCGLogger: Self { .product(name: "XCGLogger", package: "XCGLogger") }
    static var ZipArchive: Self { .product(name: "ZipArchive", package: "ZipArchive") }
}
