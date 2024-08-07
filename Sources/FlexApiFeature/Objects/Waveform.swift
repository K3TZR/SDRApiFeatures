//
//  Waveform.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 8/17/17.
//

import Foundation

import SharedFeature


@MainActor
@Observable
public final class Waveform {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization

  public init(_ objectModel: ObjectModel) {
    _objectModel = objectModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var list = ""

  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case list = "installed_list"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized  = false
  private let _objectModel: ObjectModel

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
        apiLog.warning("Waveform: unknown property, \(property.key) = \(property.value)")
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .list:   list = property.value
      }
    }
    // is it initialized?
    if _initialized == false {
      // NO, it is now
      _initialized = true
      apiLog.debug("Waveform: initialized")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  /* ----- from FlexApi -----
   "waveform uninstall " + waveform_name
   */

}
