// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SciClassification",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SciClassification", targets: ["SciClassification"])
    ],
    targets: [
        .executableTarget(name: "SciClassification")
    ]
)
