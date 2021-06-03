// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "PowerAuthShared",
    platforms: [
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v2),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "PowerAuthShared",
            targets: ["PowerAuthShared"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "PowerAuthShared",
            dependencies: []),
        .testTarget(
            name: "PowerAuthSharedTests",
            dependencies: ["PowerAuthShared"]),
    ]
)
