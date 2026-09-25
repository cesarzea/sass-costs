// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SaaS-Costs",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "SaaS-Costs", targets: ["SaaS-Costs"])
    ],
    targets: [
        .executableTarget(
            name: "SaaS-Costs",
            dependencies: [],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        )
    ]
)
