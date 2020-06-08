// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Atem",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "Atem", targets: ["Atem"]),
        .library(name: "AtemAppleDiscovery", targets: ["AtemAppleDiscovery"]),
		.executable(name: "VersionDump", targets: ["VersionDump"]),
		.executable(name: "Simulator", targets: ["Simulator"]),
		.executable(name: "TitleGenerator", targets: ["TitleGenerator"]),
		.executable(name: "PreviewSwitcher", targets: ["PreviewSwitcher"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
		.package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.5.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Atem", dependencies: ["NIO"]),
		.target(name: "AtemAppleDiscovery", dependencies: ["NIO"]),
		.target(name: "VersionDump", dependencies: ["Atem"]),
		.target(name: "Simulator", dependencies: ["Atem"]),
		.target(name: "TitleGenerator", dependencies: ["Atem"]),
		.target(name: "PreviewSwitcher", dependencies: ["Atem"]),
        .testTarget(
            name: "AtemTests",
            dependencies: ["Atem"]
		),
    ]
)
