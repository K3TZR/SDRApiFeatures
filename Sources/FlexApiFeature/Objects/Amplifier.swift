//
//  Amplifier.swift
//  ApiFeatures/Objects
//
//  Created by Douglas Adams on 8/7/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature

@MainActor
@Observable
public final class Amplifier: Identifiable, Equatable{
  public nonisolated static func == (lhs: Amplifier, rhs: Amplifier) -> Bool {
    lhs.id == rhs.id
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ apiModel: ApiModel) {
    self.id = id
    _apiModel = apiModel
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var initialized = false
  
  public var ant: String = ""
  public var antennaDict = [String:String]()
  public var handle: UInt32 = 0
  public var ip: String = ""
  public var model: String = ""
  public var port: Int = 0
  public var serialNumber: String = ""
  public var state: String = ""
  
  public enum Property: String {
    case ant
    case handle
    case ip
    case model
    case port
    case serialNumber  = "serial_num"
    case state
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _apiModel: ApiModel

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse Tnf key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Amplifier.Property(rawValue: property.key) else {
        // log it and ignore the Key
        log("Amplifier \(id.hex): unknown propety, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys
      switch token {
        
      case .ant:          ant = property.value ; antennaDict = antennaSettings( property.value)
      case .handle:       handle = property.value.handle ?? 0
      case .ip:           ip = property.value
      case .model:        model = property.value
      case .port:         port = property.value.iValue
      case .serialNumber: serialNumber = property.value
      case .state:        state = property.value
      }
      // is it initialized?
      if initialized == false {
        // NO, it is now
        initialized = true
        log("Amplifier \(id.hex): ADDED, model = \(model)", .debug, #function, #file, #line)
      }
    }
  }

  public func setProperty(_ property: Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Property, _ value: String) {
    // FIXME:
  }

  /* ----- from FlexApi -----
   amplifier set " + _handle + " operate=" + Convert.ToByte(_isOperate)
   */
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Helper methods
  
  /// Parse a list of antenna pairs
  /// - Parameter settings:     the list
  private func antennaSettings(_ settings: String) -> [String:String] {
    var antDict = [String:String]()
    
    // pairs are comma delimited
    let pairs = settings.split(separator: ",")
    // each setting is <ant:ant>
    for setting in pairs {
      if !setting.contains(":") { continue }
      let parts = setting.split(separator: ":")
      if parts.count != 2 {continue }
      antDict[String(parts[0])] = String(parts[1])
    }
    return antDict
  }
}
