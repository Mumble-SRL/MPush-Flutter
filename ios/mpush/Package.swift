// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "mpush",
  platforms: [
    .iOS("16.0")
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
      ]
    )
  ]
)
