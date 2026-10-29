// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatMedication",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatMedication", targets: ["SehatMedication"])
    ],
    dependencies: [
        .package(path: "../SehatCore"),
        .package(path: "../SehatDomain")
    ],
    targets: [
        .target(
            name: "SehatMedication",
            dependencies: [
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SehatMedicationTests",
            dependencies: [
                "SehatMedication",
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ]
        )
    ]
)
