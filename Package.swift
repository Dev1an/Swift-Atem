import PackageDescription

let package = Package(
    name: "Atem",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/vapor/socks", majorVersion: 1),
    ]
)