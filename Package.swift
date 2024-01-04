// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JVWeather",
	platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "JVWeather",
            targets: ["JVWeather"]),
    ],
	// Dependencies declare other packages that this package depends on.
	dependencies: [
		.package(url: "https://github.com/TheMisfit68/JVLocation.git", branch: "master"),
		.package(url: "https://github.com/TheMisfit68/JVSwiftCore.git", branch: "master"),
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "JVWeather",
			dependencies: ["JVLocation","JVSwiftCore"]
		),
        .testTarget(
            name: "JVWeatherTests",
            dependencies: ["JVWeather"]),
    ]
)
