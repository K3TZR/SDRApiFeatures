// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SDRApiFeatures",
  platforms: [.macOS(.v14)],
  
  products: [
    .library(name: "ClientFeature", targets: ["ClientFeature"]),
    .library(name: "DirectFeature", targets: ["DirectFeature"]),
    .library(name: "FlexApiFeature", targets: ["FlexApiFeature"]),
    .library(name: "LoginFeature", targets: ["LoginFeature"]),
    .library(name: "ListenerFeature", targets: ["ListenerFeature"]),
    .library(name: "MessagesFeature", targets: ["MessagesFeature"]),
    .library(name: "PickerFeature", targets: ["PickerFeature"]),
    .library(name: "RingBufferFeature", targets: ["RingBufferFeature"]),
    .library(name: "RxAudioFeature", targets: ["RxAudioFeature"]),
    .library(name: "SharedFeature", targets: ["SharedFeature"]),
    .library(name: "TcpFeature", targets: ["TcpFeature"]),
    .library(name: "UdpFeature", targets: ["UdpFeature"]),
    .library(name: "VitaFeature", targets: ["VitaFeature"]),
    .library(name: "XCGLogFeature", targets: ["XCGLogFeature"]),
  ],
  
  dependencies: [
    // ----- K3TZR -----
    // ----- OTHER -----
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", branch: "observation-beta"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
    .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1"),
  ],
  
  // --------------- Modules ---------------
  targets: [
    // ClientFeature
    .target(name: "ClientFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "SharedFeature"
    ]),
    
    // DirectFeature
    .target(name: "DirectFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
    ]),

    // FlexApiFeature
    .target(name: "FlexApiFeature", dependencies: [
      "ListenerFeature",
      "TcpFeature",
      "UdpFeature",
      "VitaFeature",
      "SharedFeature",
    ]),
    
    // ListenerFeature
    .target(name: "ListenerFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      .product(name: "JWTDecode", package: "JWTDecode.swift"),
      .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      "SharedFeature",
      "XCGLogFeature",
      "VitaFeature",
    ]),

    // LoginFeature
    .target(name: "LoginFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
    ]),

    // MessagesFeature
    .target(name: "MessagesFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "SharedFeature",
      "TcpFeature",
    ]),

    // PickerFeature
    .target(name: "PickerFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "ListenerFeature",
      "FlexApiFeature",
    ]),

    // RingBufferFeature
    .target( name: "RingBufferFeature", dependencies: []),
    
    // RxAudioFeature
    .target( name: "RxAudioFeature", dependencies: [
      "RingBufferFeature",
      "XCGLogFeature",
    ]),
    
    // SharedFeature
    .target(name: "SharedFeature", dependencies: [
      .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
    ]),

    // TcpFeature
    .target(name: "TcpFeature", dependencies: [
      .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      "SharedFeature",
    ]),

    // UdpFeature
    .target(name: "UdpFeature", dependencies: [
      .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      .product(name: "XCGLogger", package: "XCGLogger"),
      "SharedFeature",
      "VitaFeature",
    ]),

    // VitaFeature
    .target(name: "VitaFeature", dependencies: [
//      .product(name: "XCGLogger", package: "XCGLogger"),
//      .product(name: "ObjcExceptionBridging", package: "XCGLogger"),
      "SharedFeature",
    ]),

    // XCGLogFeature
    .target(name: "XCGLogFeature", dependencies: [
      .product(name: "XCGLogger", package: "XCGLogger"),
      .product(name: "ObjcExceptionBridging", package: "XCGLogger"),
      "SharedFeature",
    ]),
  ]
  
  // --------------- Tests ---------------
)
