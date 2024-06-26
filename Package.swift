// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoWBox",
    platforms: [
      .iOS(.v13),
      .macOS(.v10_15),
      .tvOS(.v13),
      .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CoWBox",
            targets: ["CoWBox"]
        ),
        .library(
            name: "ObservedCoWBox",
            targets: [
                "ObservedCoWBox"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.1.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CoWBox"
        ),
        .target(
            name: "ObservedCoWBox",
            dependencies: [
                .product(name: "Perception", package: "swift-perception")
            ]
        ),
        .testTarget(
            name: "CoWBoxTests",
            dependencies: ["CoWBox"]
        ),
        .testTarget(
            name: "ObservedCoWBoxTests",
            dependencies: ["ObservedCoWBox"]
        ),
    ]
)
