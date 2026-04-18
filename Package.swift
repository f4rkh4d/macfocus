// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macfocus",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "macfocus", targets: ["macfocus"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "macfocus",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "macfocusTests",
            dependencies: ["macfocus"]
        )
    ]
)
