//
//  Memory.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 8/20/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature


@MainActor
@Observable
public final class Memory: Identifiable {
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ objectModel: ObjectModel) {
    self.id = id
    _objectModel = objectModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  
  public var digitalLowerOffset = 0
  public var digitalUpperOffset = 0
  public var filterHigh = 0
  public var filterLow = 0
  public var frequency: Hz = 0
  public var group = ""
  public var mode = ""
  public var name = ""
  public var offset = 0
  public var offsetDirection = ""
  public var owner = ""
  public var rfPower = 0
  public var rttyMark = 0
  public var rttyShift = 0
  public var squelchEnabled = false
  public var squelchLevel = 0
  public var step = 0
  public var toneMode = ""
  public var toneValue: Float = 0

  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case apply
    case create
    case digitalLowerOffset         = "digl_offset"
    case digitalUpperOffset         = "digu_offset"
    case frequency                  = "freq"
    case group
    case highlight
    case highlightColor             = "highlight_color"
    case mode
    case name
    case owner
    case remove
    case repeaterOffsetDirection    = "repeater"
    case repeaterOffset             = "repeater_offset"
    case rfPower                    = "power"
    case rttyMark                   = "rtty_mark"
    case rttyShift                  = "rtty_shift"
    case rxFilterHigh               = "rx_filter_high"
    case rxFilterLow                = "rx_filter_low"
    case step
    case squelchEnabled             = "squelch"
    case squelchLevel               = "squelch_level"
    case toneMode                   = "tone_mode"
    case toneValue                  = "tone_value"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false
  private let _objectModel: ObjectModel

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Memory.Property(rawValue: property.key) else {
        // log it and ignore the Key
        apiLog.warning("Memory \(self.id): unknown property, \(property.key) = \(property.value)")
        continue
      }
      // known keys
      switch token {
        
      case .digitalLowerOffset:       digitalLowerOffset = property.value.iValue
      case .digitalUpperOffset:       digitalUpperOffset = property.value.iValue
      case .frequency:                frequency = property.value.mhzToHz
      case .group:                    group = property.value.replacingSpaces()
      case .highlight:                break   // ignored here
      case .highlightColor:           break   // ignored here
      case .mode:                     mode = property.value.replacingSpaces()
      case .name:                     name = property.value.replacingSpaces()
      case .owner:                    owner = property.value.replacingSpaces()
      case .repeaterOffsetDirection:  offsetDirection = property.value.replacingSpaces()
      case .repeaterOffset:           offset = property.value.iValue
      case .rfPower:                  rfPower = property.value.iValue
      case .rttyMark:                 rttyMark = property.value.iValue
      case .rttyShift:                rttyShift = property.value.iValue
      case .rxFilterHigh:             filterHigh = property.value.iValue
      case .rxFilterLow:              filterLow = property.value.iValue
      case .squelchEnabled:           squelchEnabled = property.value.bValue
      case .squelchLevel:             squelchLevel = property.value.iValue
      case .step:                     step = property.value.iValue
      case .toneMode:                 toneMode = property.value.replacingSpaces()
      case .toneValue:                toneValue = property.value.fValue
        
      case .apply, .create, .remove:  break   // ignored here
      }
      // is it initialized?
      if _initialized == false {
        // NO, it is now
        _initialized = true
        apiLog.debug("Memory \(self.id): ADDED")
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public set property methods
  
  public func set(_ property: Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Property, _ value: String) {
    switch property {
    case .apply, .remove:   _objectModel.sendTcp("memory \(property.rawValue) \(id)")
    case .create:           _objectModel.sendTcp("memory create")
    default:                _objectModel.sendTcp("memory set \(id) \(property.rawValue)=\(value)")
    }
    _objectModel.sendTcp("memory set \(id) \(property.rawValue)=\(value)")
  }
  
  /* ----- from FlexApi -----
   memory set " + _index + " digl_offset=" + _diglOffset
   memory set " + _index + " digu_offset=" + _diguOffset
   memory set " + _index + " freq=" + StringHelper.DoubleToString(_freq, "f6")
   memory set " + _index + " group=" + _group.Replace(' ', '\u007f')
   memory set " + _index + " name=" + _name.Replace(' ', '\u007f')
   memory set " + _index + " mode=" + _mode
   memory set " + _index + " owner=" + _owner.Replace(' ', '\u007f')
   memory set " + _index + " power=" + _rfPower
   memory set " + _index + " repeater=" + FMTXOffsetDirectionToString(_offsetDirection)
   memory set " + _index + " repeater_offset=" + StringHelper.DoubleToString(_repeaterOffset, "f6")
   memory set " + _index + " rtty_mark=" + _rttyMark
   memory set " + _index + " rtty_shift=" + _rttyShift
   memory set " + _index + " rx_filter_low=" + _rxFilterLow
   memory set " + _index + " rx_filter_high=" + _rxFilterHigh
   memory set " + _index + " squelch=" + Convert.ToByte(_squelchOn)
   memory set " + _index + " squelch_level=" + _squelchLevel
   memory set " + _index + " step=" + _step
   memory set " + _index + " tone_mode=" + FMToneModeToString(_toneMode)
   memory set " + _index + " tone_value=" + _toneValue
   
   memory apply " + _index
   memory remove " + _index
   
   memory create
   */
}
