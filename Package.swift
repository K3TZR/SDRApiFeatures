// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ViewFeatures",
  platforms: [.macOS(.v14),],
  
  products: [
    .library(name: "ClientFeature", targets: ["ClientFeature"]),
    .library(name: "LoginFeature", targets: ["LoginFeature"]),
    .library(name: "SharedFeature", targets: ["SharedFeature"]),
  ],
  
  dependencies: [
    // ----- K3TZR -----
    // ----- OTHER -----
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "observation-beta"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
  ],
  
  // --------------- Modules ---------------
  targets: [
    // ClientFeature
    .target(name: "ClientFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "SharedFeature"
    ]),
    
    // LoginFeature
    .target(name: "LoginFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
    ]),

    // SharedFeature
    .target(name: "SharedFeature", dependencies: [
      .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
    ]),
  ]
  
  // --------------- Tests ---------------
)
