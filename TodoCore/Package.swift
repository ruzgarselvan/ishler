// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TodoCore",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [.library(name: "TodoCore", targets: ["TodoCore"])],
    targets: [
        .target(name: "TodoCore"),
        .testTarget(name: "TodoCoreTests", dependencies: ["TodoCore"]),
    ]
)
