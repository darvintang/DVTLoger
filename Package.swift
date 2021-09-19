// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DVTLoger",
    platforms: [.macOS(.v10_10),
                .iOS(.v10),
                .tvOS(.v9),
                .watchOS(.v2)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "DVTLoger",
            targets: ["DVTLoger"]),
    ],
    targets: [
        .target(
            name: "DVTLoger",
            path: "Sources"),
        .testTarget(
            name: "DVTLogerTests",
            dependencies: ["DVTLoger"]),
    ]
)
