// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftSAN",
    products: [
        .library(
            name: "SwiftSAN",
            targets: ["SwiftSAN"]),
        .executable(name: "Demo", targets: ["Demo"])
    ],
    dependencies: [
        .package(url: "https://github.com/davecom/SwiftGraph.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "SwiftSAN",
            dependencies: ["SwiftGraph"]),
        .target(
            name: "Demo",
            dependencies: ["SwiftSAN"]),
        .testTarget(
            name: "SwiftSANTests",
            dependencies: ["SwiftSAN"]),
    ]
)
