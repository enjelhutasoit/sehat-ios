// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatLocalizationChecks",
    platforms: [.macOS(.v14)],
    targets: [
        .testTarget(name: "SehatLocalizationChecksTests")
    ]
)