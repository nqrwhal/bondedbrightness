// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BondedBrightness",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "BondedBrightness",
            targets: ["BondedBrightness"]
        ),
        .library(
            name: "BondedBrightnessCore",
            targets: ["BondedBrightnessCore"]
        ),
        .executable(
            name: "BondedBrightnessCoreTestRunner",
            targets: ["BondedBrightnessCoreTestRunner"]
        )
    ],
    targets: [
        .executableTarget(
            name: "BondedBrightness",
            dependencies: ["BondedBrightnessCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .target(
            name: "BondedBrightnessCore"
        ),
        .executableTarget(
            name: "BondedBrightnessCoreTestRunner",
            dependencies: ["BondedBrightnessCore"]
        )
    ]
)
