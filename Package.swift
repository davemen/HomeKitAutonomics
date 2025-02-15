// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "HomeKitAutonomic",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(name: "HAP", path: "./HAP") // Use local path instead of Git URL
    ],
    targets: [
        .executableTarget(
            name: "HomeKitAutonomic",
            dependencies: ["HAP"],
            swiftSettings: [.define("ENABLE_HAP_LOGGING")]
        )
    ]
)
