// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

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
        .library(
            name: "SwiftDataHelpersMacros",
            targets: ["SwiftDataHelpersMacros"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.5"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.4"),
    ],
    targets: [
        .macro(
            name: "SwiftDataHelpersMacroPlugin",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ]
        ),
        .target(
            name: "SwiftDataHelpersMacros",
            dependencies: [
                "SwiftDataHelpersMacroPlugin",
                "SwiftDataHelpers",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "SwiftDataHelpersMacrosTests",
            dependencies: [
                "SwiftDataHelpersMacroPlugin",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(
                    name: "MacroTesting",
                    package: "swift-macro-testing",
                    condition: .when(platforms: [.macOS])
                ),
            ]
        ),
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
