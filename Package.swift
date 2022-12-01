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
                "EmitterInterface",
            ]
        ),
        .library(
            name: "EmitterInterface",
            targets: ["EmitterInterface"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/GoodHatsLLC/Disposable.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "Emitter",
            dependencies: [
                "Disposable",
                "EmitterInterface",
            ]
        ),
        .target(
            name: "EmitterInterface",
            dependencies: [
                .product(name: "DisposableInterface", package: "Disposable"),
            ]
        ),
        .testTarget(
            name: "EmitterTests",
            dependencies: ["Emitter"]
        ),
    ]
)
