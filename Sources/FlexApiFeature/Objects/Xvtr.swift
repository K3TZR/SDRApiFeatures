//
//  Xvtr.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 6/24/17.
//

import Foundation

import SharedFeature


@MainActor
@Observable
public final class Xvtr: Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ objectModel: ObjectModel) {
    self.id = id
    _objectModel = objectModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  
  public private(set) var isValid = false
  public private(set) var preferred = false
  public private(set) var twoMeterInt = 0
  public private(set) var ifFrequency: Hz = 0
  public private(set) var loError = 0
  public private(set) var name = ""
  public private(set) var maxPower = 0
  public private(set) var order = 0
  public private(set) var rfFrequency: Hz = 0
  public private(set) var rxGain = 0
  public private(set) var rxOnly = false

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
  // MARK: - Private properties
  
  private var _initialized = false
  private let _objectModel: ObjectModel

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
        apiLog.warning("Xvtr \(self.id): unknown property, \(property.key) = \(property.value)")
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
    if _initialized == false {
      // NO, it is now
      _initialized = true
      apiLog.debug("Xvtr \(self.id): ADDED, name = \(self.name)")
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
    case .create:     _objectModel.sendTcp("xvtr create")
    case .remove:     _objectModel.sendTcp("xvtr remove \(id.hex)")
    default:          _objectModel.sendTcp("xvtr set \(id.hex) \(property.rawValue)=\(value)")
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
