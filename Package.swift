// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftDataHelpers",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "SwiftDataHelpers",
            targets: ["SwiftDataHelpers"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "SwiftDataHelpers",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .testTarget(
            name: "SwiftDataHelpersTests",
            dependencies: ["SwiftDataHelpers"]
        ),
    ]
)
