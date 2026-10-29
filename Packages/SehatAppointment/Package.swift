// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SehatAppointment",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SehatAppointment", targets: ["SehatAppointment"])
    ],
    dependencies: [
        .package(path: "../SehatCore"),
        .package(path: "../SehatDomain")
    ],
    targets: [
        .target(
            name: "SehatAppointment",
            dependencies: [
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SehatAppointmentTests",
            dependencies: [
                "SehatAppointment",
                .product(name: "SehatCore", package: "SehatCore"),
                .product(name: "SehatDomain", package: "SehatDomain")
            ]
        )
    ]
)
