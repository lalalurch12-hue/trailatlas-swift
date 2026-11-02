// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TrailAtlas",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "TrailAtlas", targets: ["TrailAtlas"])],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/elementary-swift/elementary.git", from: "0.8.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .systemLibrary(name: "CZlib", pkgConfig: "zlib", providers: [.apt(["zlib1g-dev"])]),
        .executableTarget(name: "TrailAtlas", dependencies: [
            .product(name: "Hummingbird", package: "hummingbird"),
            .product(name: "Elementary", package: "elementary"),
            .product(name: "Crypto", package: "swift-crypto"), "CZlib"
        ])
    ]
)
