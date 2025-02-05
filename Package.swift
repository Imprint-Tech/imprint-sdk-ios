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
        )
    ],
    targets: [
        .binaryTarget(
            name: "Imprint",
            path: "Imprint.xcframework"
        )
    ]
)
