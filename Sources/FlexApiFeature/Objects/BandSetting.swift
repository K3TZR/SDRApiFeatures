//
//  BandSetting.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 4/6/19.
//  Copyright © 2019 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature


@MainActor
@Observable
public final class BandSetting: Identifiable {  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ objectModel: ObjectModel) {
    self.id = id
    _objectModel = objectModel
  }
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  
  public var accTxEnabled: Bool = false
  public var accTxReqEnabled: Bool = false
  public var name = 999
  public var hwAlcEnabled: Bool = false
  public var inhibit: Bool = false
  public var rcaTxReqEnabled: Bool = false
  public var rfPower: Int = 0
  public var tunePower: Int = 0
  public var tx1Enabled: Bool = false
  public var tx2Enabled: Bool = false
  public var tx3Enabled: Bool  = false

  // ------------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case accTxEnabled       = "acc_tx_enabled"
    case accTxReqEnabled    = "acc_txreq_enable"
    case name               = "band_name"
    case hwAlcEnabled       = "hwalc_enabled"
    case inhibit
    case rcaTxReqEnabled    = "rca_txreq_enable"
    case rfPower            = "rfpower"
    case tunePower          = "tunepower"
    case tx1Enabled         = "tx1_enabled"
    case tx2Enabled         = "tx2_enabled"
    case tx3Enabled         = "tx3_enabled"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  public var _initialized = false
  public let _objectModel: ObjectModel

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse BandSetting key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = BandSetting.Property(rawValue: property.key) else {
        // log it and ignore the Key
        apiLog.warning("BandSetting \(self.id): unknown property, \(property.key) = \(property.value)")
        continue
      }
      // known keys
      switch token {
        
      case .accTxEnabled:     accTxEnabled = property.value.bValue
      case .accTxReqEnabled:  accTxReqEnabled = property.value.bValue
      case .name:             name = property.value == "GEN" ? 999 : property.value.iValue
      case .hwAlcEnabled:     hwAlcEnabled = property.value.bValue
      case .inhibit:          inhibit = property.value.bValue
      case .rcaTxReqEnabled:  rcaTxReqEnabled = property.value.bValue
      case .rfPower:          rfPower = property.value.iValue
      case .tunePower:        tunePower = property.value.iValue
      case .tx1Enabled:       tx1Enabled = property.value.bValue
      case .tx2Enabled:       tx2Enabled = property.value.bValue
      case .tx3Enabled:       tx3Enabled = property.value.bValue
      }
      // is it initialized?
      if _initialized == false {
        // NO, it is now
        _initialized = true
        apiLog.debug("BandSetting \(self.id): ADDED, name = \(self.name)")
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public set property methods
  
  public func set(_ property: Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(id, property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ id: UInt32, _ property: Property, _ value: String) {
    switch property {
    case .inhibit, .hwAlcEnabled, .rfPower, .tunePower:
      _objectModel.sendTcp("transmit bandset \(id) \(property.rawValue)=\(value)")
    case .accTxEnabled, .accTxReqEnabled, .rcaTxReqEnabled, .tx1Enabled, .tx2Enabled, .tx3Enabled:
      _objectModel.sendTcp("interlock bandset \(id) \(property.rawValue)=\(value)")
    case .name:
      break
    }
  }
  
  /* ----- from FlexApi -----
   */
}
