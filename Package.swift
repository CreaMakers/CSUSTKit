// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "csust-api-swift",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.6"),
    ],
    targets: [
        .executableTarget(
            name: "csust-api-swift",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ],
        )
    ]
)
