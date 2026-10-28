// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatDomain",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatDomain", targets: ["SehatDomain"])
    ],
    dependencies: [
        .package(path: "../SehatCore")
    ],
    targets: [
        .target(name: "SehatDomain"),
        .testTarget(
            name: "SehatDomainTests",
            dependencies: [
                "SehatDomain",
                .product(name: "SehatCore", package: "SehatCore")
            ]
        )
    ]
)