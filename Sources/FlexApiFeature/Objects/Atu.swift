//
//  Atu.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 8/15/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature
import XCGLogFeature

@MainActor
@Observable
public final class Atu: Equatable {
  public nonisolated static func == (lhs: Atu, rhs: Atu) -> Bool {
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ apiModel: ApiModel) {
    _apiModel = apiModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public internal(set) var initialized  = false
  
  public var enabled: Bool = false
  public var memoriesEnabled: Bool = false
  public var status: Status = .none
  public var usingMemory: Bool = false
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _apiModel: ApiModel

  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Status: String {
    case none             = "NONE"
    case tuneNotStarted   = "TUNE_NOT_STARTED"
    case tuneInProgress   = "TUNE_IN_PROGRESS"
    case tuneBypass       = "TUNE_BYPASS"           // Success Byp
    case tuneSuccessful   = "TUNE_SUCCESSFUL"       // Success
    case tuneOK           = "TUNE_OK"
    case tuneFailBypass   = "TUNE_FAIL_BYPASS"      // Byp
    case tuneFail         = "TUNE_FAIL"
    case tuneAborted      = "TUNE_ABORTED"
    case tuneManualBypass = "TUNE_MANUAL_BYPASS"    // Byp
  }
  
  public enum Property: String {
    case status
    case enabled            = "atu_enabled"
    case memoriesEnabled    = "memories_enabled"
    case usingMemory        = "using_mem"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse status message
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown Keys
      guard let token = Atu.Property(rawValue: property.key)  else {
        // log it and ignore the Key
        log("Atu: unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .enabled:          enabled = property.value.bValue
      case .memoriesEnabled:  memoriesEnabled = property.value.bValue
      case .status:           status = Atu.Status(rawValue: property.value) ?? .none
      case .usingMemory:      usingMemory = property.value.bValue
      }
    }
    // is it initialized?
    if initialized == false{
      // NO, it is now
      initialized = true
      log("Atu: initialized", .debug, #function, #file, #line)
    }
  }
  
  public func setProperty(_ property: Property, _ value: String) {
    guard property == .enabled || property == .memoriesEnabled else { return }
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Property, _ value: String) {
    switch property {
    case .enabled:            _apiModel.sendCommand("atu \(value == "1" ? "start": "bypass")")
    case .memoriesEnabled:    _apiModel.sendCommand("atu set \(property.rawValue)=\(value)")
    default:                  break
    }
  }
  
  /* ----- from FlexApi -----
   "atu set memories_enabled=" + Convert.ToByte(_atuMemoriesEnabled)
   "atu start"
   "atu bypass"
   "atu clear"
   */
}
