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
    
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMajor(from: "2.1.1")),
    ],

    targets: [
        .target(
            name: "DVTLoger",
            dependencies: ["Zip"],
            path: "Sources"
        ),
        .testTarget(
            name: "DVTLogerTests",
            dependencies: ["DVTLoger"]
        ),
    ],
    
    swiftLanguageVersions: [.v5]
)
