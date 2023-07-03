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
      .upToNextMinor(from: "1.0.0")
    ),
  ],
  targets: [
    .target(
      name: "Emitter",
      dependencies: [
        "Disposable",
      ],
      swiftSettings: Env.swiftSettings
    ),
    .testTarget(
      name: "EmitterTests",
      dependencies: ["Emitter", "Disposable"]
    ),
  ]
)

// MARK: - Env

private enum Env {
  static let swiftSettings: [SwiftSetting] = {
    var settings: [SwiftSetting] = []
    settings.append(contentsOf: [
      .enableUpcomingFeature("ConciseMagicFile"),
      .enableUpcomingFeature("ExistentialAny"),
      .enableUpcomingFeature("StrictConcurrency"),
      .enableUpcomingFeature("ImplicitOpenExistentials"),
      .enableUpcomingFeature("BareSlashRegexLiterals"),
    ])
    return settings
  }()
}
