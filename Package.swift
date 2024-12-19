// swift-tools-version: 5.5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SuiKit",
    platforms: [.iOS(.v14), .macOS(.v11), .watchOS(.v7), .tvOS(.v13)],
    products: [
        .library(
            name: "SuiKit",
            targets: ["SuiKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hyugit/UInt256.git", from: "0.2.2"),
        .package(url: "https://github.com/pebble8888/ed25519swift.git", from: "1.2.7"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
        .package(url: "https://github.com/tesseract-one/Blake2.swift.git", from: "0.2.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.0"),
        .package(url: "https://github.com/tesseract-one/Bip39.swift.git", from: "0.1.1"),
        .package(url: "https://github.com/auth0/JWTDecode.swift", from: "3.1.0"),
        .package(url: "https://github.com/apollographql/apollo-ios.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0"),
        .package(url: "https://github.com/web3swift-team/web3swift", .exactItem("3.2.1"))
    ],
    targets: [
        .target(
            name: "SuiKit",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "UInt256", package: "UInt256"),
                .product(name: "ed25519swift", package: "ed25519swift"),
                .product(name: "SwiftyJSON", package: "swiftyjson"),
                .product(name: "Blake2", package: "Blake2.swift"),
                .product(name: "AnyCodable", package: "AnyCodable"),
                .product(name: "Bip39", package: "Bip39.swift"),
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "JWTDecode", package: "JWTDecode.swift"),
                .product(name: "web3swift", package: "web3swift")
            ]
        ),
        .testTarget(
            name: "SuiKitTests",
            dependencies: ["SuiKit"],
            path: "Tests",
            resources: [.copy("Resources")]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
