//
//  Equalizer.swift
//  ApiFeatures/Objects
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

import SharedFeature

@MainActor
//@Observable
public final class Equalizer: Identifiable, Equatable {
  public nonisolated static func == (lhs: Equalizer, rhs: Equalizer) -> Bool {
    lhs.id == rhs.id
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: String) { self.id = id }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: String
  public var initialized = false
  
  public var eqEnabled = false
  public var hz63: Int = 0
  public var hz125: Int = 0
  public var hz250: Int = 0
  public var hz500: Int = 0
  public var hz1000: Int = 0
  public var hz2000: Int = 0
  public var hz4000: Int = 0
  public var hz8000: Int = 0
  
  public enum Kind: String {
    case rx = "rxsc"
    case tx = "txsc"
  }
  
  public enum Property: String {
    // properties received from the radio
    case hz63   = "63hz"
    case hz125  = "125hz"
    case hz250  = "250hz"
    case hz500  = "500hz"
    case hz1000 = "1000hz"
    case hz2000 = "2000hz"
    case hz4000 = "4000hz"
    case hz8000 = "8000hz"
    case eqEnabled = "mode"
  }
  static let altProperty: [Property : String] = [
    // alternate properties REQUIRED when sending to the radio
    .hz63 : "63Hz",
    .hz125 : "125Hz",
    .hz250 : "250Hz",
    .hz500 : "500Hz",
    .hz1000 : "1000Hz",
    .hz2000 : "2000Hz",
    .hz4000 : "4000Hz",
    .hz8000 : "8000Hz"
  ]

  
  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Equalizer.Property(rawValue: property.key) else {
        // log it and ignore the Key
        log("Equalizer \(id): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys
      switch token {
        
      case .hz63:      hz63 = property.value.iValue
      case .hz125:    hz125 = property.value.iValue
      case .hz250:    hz250 = property.value.iValue
      case .hz500:    hz500 = property.value.iValue
      case .hz1000:  hz1000 = property.value.iValue
      case .hz2000:  hz2000 = property.value.iValue
      case .hz4000:  hz4000 = property.value.iValue
      case .hz8000:  hz8000 = property.value.iValue
        
      case .eqEnabled:        eqEnabled = property.value.bValue
      }
      // is it initialized?
      if initialized == false {
        // NO, it is now
        initialized = true
        log("Equalizer \(id): ADDED", .debug, #function, #file, #line)
      }
    }
  }
  
  public func setProperty(_ property: Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  public func flat() {
    setProperty(.hz63, "0")
    setProperty(.hz125, "0")
    setProperty(.hz250, "0")
    setProperty(.hz500, "0")
    setProperty(.hz1000, "0")
    setProperty(.hz2000, "0")
    setProperty(.hz4000, "0")
    setProperty(.hz8000, "0")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Property, _ value: String) {
    var rawProperty = property.rawValue
    
    // is there an alternate property REQUIRED when sending to the radio?
    if let altValue = Equalizer.altProperty[property] {
      // YES
      rawProperty = altValue
    }
    ApiModel.shared.sendCommand("eq \(id) \(rawProperty)=\(value)")
  }

  /* ----- from FlexApi -----
   eq " + id + "mode="   + 1/0
   eq " + id + "32Hz="   + hz32
   eq " + id + "63Hz="   + hz63
   eq " + id + "125Hz="  + hz125
   eq " + id + "250Hz="  + hz250
   eq " + id + "500Hz="  + hz500
   eq " + id + "1000Hz=" + hz1000
   eq " + id + "2000Hz=" + hz2000
   eq " + id + "4000Hz=" + hz4000
   eq " + id + "8000Hz=" + hz8000
   eq " + id + "info"
   eq apf gain=" + apfGain
   eq apf mode=" + apfMode
   eq apf qfactor=" + apfQFactor
   */
}
