//
//  Tnf.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 6/30/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature
import XCGLogFeature

@MainActor
@Observable
public final class Tnf: Identifiable, Equatable, Comparable {
  public nonisolated static func < (lhs: Tnf, rhs: Tnf) -> Bool {
    lhs.id < rhs.id
  }
  
  public nonisolated static func == (lhs: Tnf, rhs: Tnf) -> Bool {
    lhs.id == rhs.id
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ id: UInt32) {
    self.id = id
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  
  public private(set) var depth: UInt = 0
  public private(set) var frequency: Hz = 0
  public private(set) var permanent = false
  public private(set) var width: Hz = 0

  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case depth
    case frequency = "freq"
    case permanent
    case width
  }
  
  public enum Depth : UInt {
    case normal   = 1
    case deep     = 2
    case veryDeep = 3
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse Tnf properties
  /// - Parameter properties: a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Tnf.Property(rawValue: property.key) else {
        // log it and ignore the Key
        log("Tnf \(id): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys
      switch token {
        
      case .depth:      depth = property.value.uValue
      case .frequency:  frequency = property.value.mhzToHz
      case .permanent:  permanent = property.value.bValue
      case .width:      width = property.value.mhzToHz
      }
      // is it initialized?
      if _initialized == false && frequency != 0 {
        // NO, it is now
        _initialized = true
        log("Tnf \(id): ADDED, frequency = \(frequency.hzToMhz)", .debug, #function, #file, #line)
      }
    }
  }
  
  public func remove(callback: ReplyHandler? = nil) {
    ObjectModel.shared.sendTcp("tnf remove " + " \(id)", replyTo: callback)

    // remove it immediately (Tnf does not send status on removal)
    ObjectModel.shared.tnfs.remove(id: id)
    log("Tnf, removed: id = \(id)", .debug, #function, #file, #line)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public set property methods
  
  public func setProperty(_ property: Tnf.Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
//  public func sendProperty(_ property: Tnf.Property, _ value: String) {
//    parse([(property.rawValue, value)])
//    send(property, value)
//  }
 
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Tnf.Property, _ value: String) {
    ObjectModel.shared.sendTcp("tnf set \(id) \(property.rawValue)=\(value)")
  }

  /* ----- from FlexApi -----
   "tnf set " + _id + " freq=" + StringHelper.DoubleToString(_frequency, "f6")
   "tnf set " + _id + " depth=" + _depth
   "tnf set " + _id + " permanent=" + _permanent
   "tnf set " + _id + " width=" + StringHelper.DoubleToString(_bandwidth, "f6")
   "tnf remove " + _id
   */

}
