// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Imprint",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "Imprint",
            targets: ["Imprint"]
        ),
        .library(
            name: "ImprintSDKCore",
            targets: ["ImprintSDKCore"]
        )
    ],
    targets: [
        .target(
            name: "ImprintSDKCore",
            path: "Sources",
            exclude: [],
            sources: ["."],
            resources: [],
            publicHeadersPath: nil,
            cSettings: [],
            swiftSettings: [],
            linkerSettings: []
        ),
        .target(
            name: "Imprint",
            dependencies: ["ImprintSDKCore"],
            path: "Compatibility"
        )
    ]
)
