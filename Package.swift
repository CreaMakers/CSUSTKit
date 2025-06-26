// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "csust-api-swift",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.8"),
        .package(url: "https://github.com/juri/dotenvy.git", from: "0.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "csust-api-swift",
            dependencies: [
                .product(name: "Alamofire", package: "alamofire"),
                .product(name: "SwiftSoup", package: "swiftsoup"),
                .product(name: "DotEnvy", package: "dotenvy"),
            ],
        )
    ]
)
