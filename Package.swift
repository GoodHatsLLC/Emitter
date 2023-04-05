// swift-tools-version: 5.8

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
    .package(
      url: "https://github.com/GoodHatsLLC/Disposable.git",
      from: .init(0, 8, 0)
    ),
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
      dependencies: ["Emitter", "Disposable"]
    ),
  ]
)
