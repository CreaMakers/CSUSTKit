// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CSUSTKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(name: "CSUSTKit", targets: ["CSUSTKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.2")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.8.8"),
        .package(url: "https://github.com/juri/dotenvy.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "CSUSTKit",
            dependencies: [
                .product(name: "Alamofire", package: "alamofire"),
                .product(name: "SwiftSoup", package: "swiftsoup"),
            ],
            path: "Sources"
        ),
        .executableTarget(
            name: "CSUSTKitExample",
            dependencies: [
                "CSUSTKit",
                .product(name: "DotEnvy", package: "dotenvy"),
            ],
            path: "Examples"
        ),
    ]
)
