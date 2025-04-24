// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "GamepadSwift",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "GamepadSwift",
            targets: ["GamepadSwift"]),
    ],
    targets: [
        .executableTarget(
            name: "GamepadSwift",
            dependencies: [],
            path: "Sources",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
