// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Atem",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Atem",
            targets: ["Atem"]),
			.executable(name: "Version dump", targets: ["Version dump"]),
			.executable(name: "Simulator", targets: ["Simulator"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Atem",
            dependencies: ["NIO"]),
		.target(name: "Version dump", dependencies: ["Atem"]),
		.target(name: "Simulator", dependencies: ["Atem"]),
        .testTarget(
            name: "Atem Tests",
            dependencies: ["Atem"]),
    ]
)
