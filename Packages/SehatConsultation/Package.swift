// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatConsultation",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatConsultation", targets: ["SehatConsultation"])
    ],
    dependencies: [
        .package(path: "../SehatCore"),
        .package(path: "../SehatDomain")
    ],
    targets: [
        .target(
            name: "SehatConsultation",
            dependencies: [
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SehatConsultationTests",
            dependencies: [
                "SehatConsultation",
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ]
        )
    ]
)
