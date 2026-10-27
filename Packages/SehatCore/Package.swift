// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SehatCore", targets: ["SehatCore"])
    ],
    targets: [
        .target(name: "SehatCore"),
        .testTarget(name: "SehatCoreTests", dependencies: ["SehatCore"])
    ]
)
