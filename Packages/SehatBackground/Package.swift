// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatBackground",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatBackground", targets: ["SehatBackground"])
    ],
    targets: [
        .target(name: "SehatBackground"),
        .testTarget(name: "SehatBackgroundTests", dependencies: ["SehatBackground"])
    ]
)