// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-hub",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .executable(name: "hub-cli", targets: ["HubCLI"]),
    .library(name: "Hub", targets: ["Hub"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0")
  ],
  targets: [
    .executableTarget(
      name: "HubCLI",
      dependencies: ["Hub", .product(name: "ArgumentParser", package: "swift-argument-parser")]),
    .target(name: "Hub", resources: [.process("FallbackConfigs")]),
    .testTarget(name: "HubTests", dependencies: ["Hub"]),
  ]
)
