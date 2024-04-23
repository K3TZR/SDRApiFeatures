//
//  Waveform.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 8/17/17.
//

import Foundation

import SharedFeature
import XCGLogFeature

@MainActor
@Observable
public final class Waveform {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public internal(set) var initialized  = false

  public var list = ""

  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case list = "installed_list"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse a Waveform status message
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = Waveform.Property(rawValue: property.key)  else {
        // log it and ignore the Key
        log("Waveform: unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .list:   list = property.value
      }
    }
    // is it initialized?
    if initialized == false {
      // NO, it is now
      initialized = true
      log("Waveform: initialized", .debug, #function, #file, #line)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  /* ----- from FlexApi -----
   "waveform uninstall " + waveform_name
   */

}
