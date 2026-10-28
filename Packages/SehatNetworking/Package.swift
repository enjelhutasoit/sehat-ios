// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatNetworking",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatNetworking", targets: ["SehatNetworking"])
    ],
    dependencies: [
        .package(path: "../SehatCore")
    ],
    targets: [
        .target(
            name: "SehatNetworking",
            dependencies: [.product(name: "SehatCore", package: "SehatCore")]
        ),
        .testTarget(
            name: "SehatNetworkingTests",
            dependencies: [
                "SehatNetworking",
                .product(name: "SehatCore", package: "SehatCore")
            ]
        )
    ]
)