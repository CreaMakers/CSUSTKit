// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "csust-api-swift",
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0"))
    ],
    targets: [
        .executableTarget(
            name: "csust-api-swift",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ]
        )
    ]
)
