// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScovilleKit",
    // 👇 Declare the minimum supported Apple platforms
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces.
        .library(
            name: "ScovilleKit",
            targets: ["ScovilleKit"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        .target(
            name: "ScovilleKit",
            path: "Sources"
        ),
        .testTarget(
            name: "ScovilleKitTests",
            dependencies: ["ScovilleKit"],
            path: "Tests"
        ),
    ]
)
