// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacTools",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "ScreenInk", targets: ["ScreenInk"])],
    targets: [
        .target(name: "InkCore"),
        .executableTarget(name: "ScreenInk", dependencies: ["InkCore"]),
        .testTarget(name: "InkCoreTests", dependencies: ["InkCore"]),
        .testTarget(name: "ScreenInkTests", dependencies: ["ScreenInk"])
    ]
)
