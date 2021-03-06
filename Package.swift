// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "filmlocationsservice",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "filmlocationsservice",
            targets: ["filmlocationsservice"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "1.7.9"),
        .package(url: "https://github.com/OpenKitten/MongoKitten.git", from: "4.1.0"),
        .package(url: "https://github.com/IBM-Swift/Kitura-CORS", from: "1.7.0"),
        .package(url: "https://github.com/IBM-Swift/HeliumLogger.git", from: "1.7.1"),
        .package(url: "https://github.com/SwiftOnTheServer/SwiftDotEnv", from: "1.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "filmlocationsservice",
            dependencies: ["Kitura", "MongoKitten", "KituraCORS", "HeliumLogger", "SwiftDotEnv"]),
        .testTarget(
            name: "serviceTests",
            dependencies: ["filmlocationsservice"])
    ]
)
