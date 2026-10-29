// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatDiagnostics",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatDiagnostics", targets: ["SehatDiagnostics"])
    ],
    dependencies: [
        .package(path: "../SehatCore")
    ],
    targets: [
        .target(
            name: "SehatDiagnostics",
            dependencies: [.product(name: "SehatCore", package: "SehatCore")]
        ),
        .testTarget(
            name: "SehatDiagnosticsTests",
            dependencies: [
                "SehatDiagnostics",
                .product(name: "SehatCore", package: "SehatCore")
            ]
        )
    ]
)
