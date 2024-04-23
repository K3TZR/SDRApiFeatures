//
//  Xvtr.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 6/24/17.
//

import Foundation

import SharedFeature
import XCGLogFeature

@MainActor
@Observable
public final class Xvtr: Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) {
    self.id = id
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var initialized = false
  
  public var isValid = false
  public var preferred = false
  public var twoMeterInt = 0
  public var ifFrequency: Hz = 0
  public var loError = 0
  public var name = ""
  public var maxPower = 0
  public var order = 0
  public var rfFrequency: Hz = 0
  public var rxGain = 0
  public var rxOnly = false

  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case create
    case ifFrequency    = "if_freq"
    case isValid        = "is_valid"
    case loError        = "lo_error"
    case maxPower       = "max_power"
    case name
    case order
    case preferred
    case remove
    case rfFrequency    = "rf_freq"
    case rxGain         = "rx_gain"
    case rxOnly         = "rx_only"
    case twoMeterInt    = "two_meter_int"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse Xvtr key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Xvtr.Property(rawValue: property.key) else {
        // log it and ignore the Key
        log("Xvtr \(id): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .name:         name = String(property.value.prefix(4))
      case .ifFrequency:  ifFrequency = property.value.mhzToHz
      case .isValid:      isValid = property.value.bValue
      case .loError:      loError = property.value.iValue
      case .maxPower:     maxPower = property.value.iValue
      case .order:        order = property.value.iValue
      case .preferred:    preferred = property.value.bValue
      case .rfFrequency:  rfFrequency = property.value.mhzToHz
      case .rxGain:       rxGain = property.value.iValue
      case .rxOnly:       rxOnly = property.value.bValue
      case .twoMeterInt:  twoMeterInt = property.value.iValue
        
      case .create:       break  // ignored here
      case .remove:       break  // ignored here
      }
    }
    // is it initialized?
    if initialized == false {
      // NO, it is now
      initialized = true
      log("Xvtr \(id): ADDED, name = \(name)", .debug, #function, #file, #line)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public set property methods
  
  public func setProperty(_ property: Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Property, _ value: String) {
    switch property {
    case .create:     ApiModel.shared.sendCommand("xvtr create")
    case .remove:     ApiModel.shared.sendCommand("xvtr remove \(id.hex)")
    default:          ApiModel.shared.sendCommand("xvtr set \(id.hex) \(property.rawValue)=\(value)")
    }
  }
  
  /* ----- from FlexApi -----
   xvtr create
   xvtr remove " + _index
   
   xvtr set " + _index + " name=" + _name
   xvtr set " + _index + " if_freq=" + StringHelper.DoubleToString(_ifFreq, "f6")
   xvtr set " + _index + " lo_error=" + StringHelper.DoubleToString(_loError, "f6")
   xvtr set " + _index + " max_power=" + StringHelper.DoubleToString(_maxPower, "f2")
   xvtr set " + _index + " order=" + _order
   xvtr set " + _index + " rf_freq=" + StringHelper.DoubleToString(_rfFreq, "f6")
   xvtr set " + _index + " rx_gain=" + StringHelper.DoubleToString(_rxGain, "f2")
   xvtr set " + _index + " rx_only=" + Convert.ToByte(_rxOnly)
   */
}
