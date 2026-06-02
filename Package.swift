// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WhispyAI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "WhispyAI",
            targets: ["WhispyAI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "WhispyAI",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "WhispyAITests",
            dependencies: ["WhispyAI"]
        ),
    ]
)
