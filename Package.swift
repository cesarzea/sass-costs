// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SaaSCosts",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(name: "SaaSCosts"),
        .testTarget(name: "SaaSCostsTests", dependencies: ["SaaSCosts"])
    ]
)
