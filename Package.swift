// swift-tools-version:5.5
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
		.executable(name: "PreviewSwitcher", targets: ["PreviewSwitcher"]),
		.executable(name: "SourceLabeler", targets: ["SourceLabeler"]),
		.executable(name: "MessageDecoder", targets: ["MessageDecoder"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.32.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(name: "Atem", dependencies: [.product(name: "NIO", package: "swift-nio")]),
		.target(name: "AtemAppleDiscovery", dependencies: [.product(name: "NIO", package: "swift-nio")]),
		.executableTarget(name: "VersionDump", dependencies: ["Atem"]),
		.executableTarget(name: "Simulator", dependencies: ["Atem"]),
		.executableTarget(name: "TitleGenerator", dependencies: ["Atem"]),
		.executableTarget(name: "PreviewSwitcher", dependencies: ["Atem"]),
		.executableTarget(name: "SourceLabeler", dependencies: ["Atem"]),
		.executableTarget(name: "MessageDecoder", dependencies: ["Atem"]),
        .testTarget(
            name: "AtemTests",
            dependencies: ["Atem"]
		),
    ]
)
