// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DVTLoger",

    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
    ],

    products: [
        .library(
            name: "DVTLoger",
            targets: ["DVTLoger"]
        ),
    ],

    targets: [
        .target(
            name: "DVTLoger",
            path: "Sources"
        ),
        .testTarget(
            name: "DVTLogerTests",
            dependencies: ["DVTLoger"]
        ),
    ],
    
    swiftLanguageVersions: [.v5]
)
