// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DVTLoger",

    platforms: [
        .iOS(.v13)
    ],

    products: [
        .library(
            name: "DVTLoger",
            targets: ["DVTLoger"]
        ),
    ],
    
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip.git", .upToNextMinor(from: "2.1.2"))
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
        )
    ]
)
