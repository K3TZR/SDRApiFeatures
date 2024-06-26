// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SDRApiFeatures",
  platforms: [.macOS(.v14)],
  
  products: [
    .library(name: "AudioFeature", targets: ["AudioFeature"]),
    .library(name: "CustomControlFeature", targets: ["CustomControlFeature"]),
    .library(name: "ClientFeature", targets: ["ClientFeature"]),
    .library(name: "DirectFeature", targets: ["DirectFeature"]),
    .library(name: "FlagAntennaFeature", targets: ["FlagAntennaFeature"]),
    .library(name: "FlagFeature", targets: ["FlagFeature"]),
    .library(name: "FlexApiFeature", targets: ["FlexApiFeature"]),
    .library(name: "ListenerFeature", targets: ["ListenerFeature"]),
    .library(name: "LoginFeature", targets: ["LoginFeature"]),
//    .library(name: "PanadapterFeature", targets: ["PanadapterFeature"]),
//    .library(name: "PanafallFeature", targets: ["PanafallFeature"]),
    .library(name: "PickerFeature", targets: ["PickerFeature"]),
    .library(name: "RingBufferFeature", targets: ["RingBufferFeature"]),
    .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
    .library(name: "SharedFeature", targets: ["SharedFeature"]),
    .library(name: "SideControlsFeature", targets: ["SideControlsFeature"]),
    .library(name: "VitaFeature", targets: ["VitaFeature"]),
//    .library(name: "WaterfallFeature", targets: ["WaterfallFeature"]),
  ],
  
  dependencies: [
    .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket", from: "7.6.5"),
    .package(url: "https://github.com/auth0/JWTDecode.swift", from: "2.6.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.2"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
  ],
  
  // --------------- Modules ---------------
  targets: [
    // AudioFeature
    .target( name: "AudioFeature", dependencies: [
      "SharedFeature",
      "VitaFeature",
      "RingBufferFeature",
    ]),
    
    // ClientFeature
    .target(name: "ClientFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "SharedFeature"
    ]),
    
    // CustomControlFeature
    .target(name: "CustomControlFeature", dependencies: [
      "SharedFeature",
    ]),
    
    // DirectFeature
    .target(name: "DirectFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
    ]),

    // FlagAntennaFeature
    .target(name: "FlagAntennaFeature", dependencies: [
      "FlexApiFeature",
    ]),

    // FlagFeature
    .target(name: "FlagFeature", dependencies: [
      "FlagAntennaFeature",
      "CustomControlFeature",
      "FlexApiFeature",
      "SharedFeature",
    ]),

    // FlexApiFeature
    .target(name: "FlexApiFeature", dependencies: [
      "AudioFeature",
      "ListenerFeature",
      "SharedFeature",
      "VitaFeature",
    ]),
    
    // ListenerFeature
    .target(name: "ListenerFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      .product(name: "JWTDecode", package: "JWTDecode.swift"),
      .product(name: "CocoaAsyncSocket", package: "CocoaAsyncSocket"),
      "SharedFeature",
      "VitaFeature",
    ]),

    // LoginFeature
    .target(name: "LoginFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
    ]),

    // PanadapterFeature
//    .target(name: "PanadapterFeature", dependencies: [
//      "FlagFeature",
//      "FlexApiFeature",
//    ]),
    
    // PanafallFeature
//    .target(name: "PanafallFeature", dependencies: [
//      "PanadapterFeature",
//      "WaterfallFeature",
//      "FlexApiFeature",
//    ]),

    // PickerFeature
    .target(name: "PickerFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "ListenerFeature",
      "FlexApiFeature",
    ]),

    // RingBufferFeature
    .target( name: "RingBufferFeature", dependencies: []),
    
    // SettingsFeature
    .target(name: "SettingsFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "FlexApiFeature",
    ]),

    // SharedFeature
    .target(name: "SharedFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
    ]),

    // SideControlsFeature
    .target(name: "SideControlsFeature", dependencies: [
      .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      "CustomControlFeature",
      "FlexApiFeature",
      "SharedFeature"
    ]),
    
    // VitaFeature
    .target(name: "VitaFeature", dependencies: [
      "SharedFeature",
    ]),

    // WaterfallFeature
//    .target(
//      name: "WaterfallFeature",
//      
//      dependencies: [
//        "FlexApiFeature",
//      ],
//      resources: [
//        .copy("Gradients/Basic.tex"),
//        .copy("Gradients/Dark.tex"),
//        .copy("Gradients/Deuteranopia.tex"),
//        .copy("Gradients/Grayscale.tex"),
//        .copy("Gradients/Purple.tex"),
//        .copy("Gradients/Tritanopia.tex"),
//      ]
//    )
  ]
  
  // --------------- Tests ---------------
)
