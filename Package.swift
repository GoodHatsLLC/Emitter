// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Emitter",
  platforms: [.macOS(.v10_15), .iOS(.v14)],
  products: [
    .library(
      name: "Emitter",
      targets: [
        "Emitter",
      ]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/GoodHatsLLC/Disposable.git", from: "0.4.0"),
  ],
  targets: [
    .target(
      name: "Emitter",
      dependencies: [
        "Disposable",
      ]
    ),
    .testTarget(
      name: "EmitterTests",
      dependencies: ["Emitter"]
    ),
  ]
)
