// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "PowerAuthShared",
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
