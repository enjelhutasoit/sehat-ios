// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatWidgetSupport",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatWidgetSupport", targets: ["SehatWidgetSupport"])
    ],
    dependencies: [
        .package(path: "../SehatCore"),
        .package(path: "../SehatDomain")
    ],
    targets: [
        .target(
            name: "SehatWidgetSupport",
            dependencies: [
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ]
        ),
        .testTarget(
            name: "SehatWidgetSupportTests",
            dependencies: [
                "SehatWidgetSupport",
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ]
        )
    ]
)