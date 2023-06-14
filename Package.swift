// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "Emitter",
  platforms: [
    .macOS("12.3"),
    .iOS("15.4"),
    .tvOS("15.4"),
    .watchOS("8.5"),
    .macCatalyst("15.4"),
  ],
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
