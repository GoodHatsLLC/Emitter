// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Benchmarks",
  platforms: [.macOS(.v10_15), .iOS(.v14)],
  products: [
    .executable(name: "emitter-benchmark", targets: ["Benchmarks"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/apple/swift-collections-benchmark.git", from: "0.0.3"),
    .package(name: "Emitter", path: "../"),
  ],
  targets: [
    .executableTarget(
      name: "Benchmarks",
      dependencies: [
        "Emitter",
        .product(name: "CollectionsBenchmark", package: "swift-collections-benchmark"),
      ]
    ),
  ]
)
