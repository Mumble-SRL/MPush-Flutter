// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mpush",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "mpush", targets: ["mpush"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "mpush",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // The plugin reads/writes shared data through UserDefaults (a required
                // reason API), so the privacy manifest is bundled with the target.
                .process("PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("UserNotifications")
            ]
        )
    ]
)
