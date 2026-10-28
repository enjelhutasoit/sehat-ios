// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatPersistence",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatPersistence", targets: ["SehatPersistence"])
    ],
    dependencies: [
        .package(path: "../SehatCore"),
        .package(path: "../SehatDomain")
    ],
    targets: [
        .target(
            name: "SehatPersistence",
            dependencies: [
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ]
        ),
        .testTarget(
            name: "SehatPersistenceTests",
            dependencies: [
                "SehatPersistence",
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ]
        )
    ]
)