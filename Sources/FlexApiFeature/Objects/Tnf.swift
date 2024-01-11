//
//  Tnf.swift
//  ApiFeatures/Objects
//
//  Created by Douglas Adams on 6/30/15.
//  Copyright © 2015 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature

@MainActor
@Observable
public final class Tnf: Identifiable, Equatable {
  public nonisolated static func == (lhs: Tnf, rhs: Tnf) -> Bool {
    lhs.id == rhs.id
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ id: UInt32, _ apiModel: ApiModel) {
    self.id = id
    _apiModel = apiModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var initialized = false
  
  public var depth: UInt = 0
  public var frequency: Hz = 0
  public var permanent = false
  public var width: Hz = 0

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
  
  private var _apiModel: ApiModel

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
      if initialized == false && frequency != 0 {
        // NO, it is now
        initialized = true
        log("Tnf \(id): ADDED, frequency = \(frequency.hzToMhz)", .debug, #function, #file, #line)
      }
    }
  }
  
  public func remove(callback: ReplyHandler? = nil) {
    _apiModel.sendCommand("tnf remove " + " \(id)", replyTo: callback)

    // remove it immediately (Tnf does not send status on removal)
    _apiModel.tnfs.remove(id: id)
    log("Tnf, removed: id = \(id)", .debug, #function, #file, #line)
  }

  public func setProperty(_ property: Tnf.Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Tnf.Property, _ value: String) {
    _apiModel.sendCommand("tnf set \(id) \(property.rawValue)=\(value)")
  }

  /* ----- from FlexApi -----
   "tnf set " + _id + " freq=" + StringHelper.DoubleToString(_frequency, "f6")
   "tnf set " + _id + " depth=" + _depth
   "tnf set " + _id + " permanent=" + _permanent
   "tnf set " + _id + " width=" + StringHelper.DoubleToString(_bandwidth, "f6")
   "tnf remove " + _id
   */

}
