//
//  Profile.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 8/17/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature
import XCGLogFeature

@MainActor
@Observable
public final class Profile: Identifiable, Equatable{
  public nonisolated static func == (lhs: Profile, rhs: Profile) -> Bool {
    lhs.id == rhs.id
  }

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: String, _ apiModel: ApiModel) {
    self.id = id
    _apiModel = apiModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: String
  public var initialized = false
  
  public var current: String = ""
  public var list = [String]()
  
  public enum Property: String {
    case list = "list"
    case current = "current"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _apiModel: ApiModel

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse Profile key/value pairs
  /// - Parameter statusMessage:       String
  public func parse(_ statusMessage: String?) {
    guard statusMessage != nil else { return }
    
    let properties = statusMessage!.keyValuesArray(delimiter: " ")
    let id = properties[0].key
    
    // check for unknown Key
    guard let token = Profile.Property(rawValue: properties[1].key) else {
      // log it and ignore the Key
      log("Profile \(id): unknown property, \(properties[1].key)", .warning, #function, #file, #line)
      return
    }
    // known keys
    switch token {
    case .list:
      let i = statusMessage!.index(statusMessage!.firstIndex(of: "=")!, offsetBy: 1)
      let suffix = String(statusMessage!.suffix(from: i))
      
      let values = suffix.valuesArray(delimiter: "^")
      var valuesList = [String]()
      for value in values {
        if !value.isEmpty { valuesList.append(value) }
      }
      list = valuesList
      
    case .current:
      let i = statusMessage!.index(statusMessage!.firstIndex(of: "=")!, offsetBy: 1)
      let suffix = String(statusMessage!.suffix(from: i))
      current = suffix.isEmpty ? "none" : suffix
      
    }
    // is it initialized?
    if initialized == false {
      // NO, it is now
      initialized = true
      log("Profile \(id): ADDED", .debug, #function, #file, #line)
    }
  }
  
  public func setProperty(_ cmd: String, _ profileName: String) {
    guard id == "mic" || id == "tx" || id == "global" else { return }
    
    switch cmd {
    case "delete":
      _apiModel.sendCommand("profile \(id) delete \"\(profileName)\"")
      list.removeAll(where: { $0 == profileName })
    case "create":
      list.append(profileName)
      _apiModel.sendCommand("profile \(id) " + "create \"\(profileName)\"")
    case "reset":
      _apiModel.sendCommand("profile \(id) " + "reset \"\(profileName)\"")
    default:
      current = profileName
      _apiModel.sendCommand("profile \(id) " + "load \"\(profileName)\"")
    }
  }

  /* ----- from FlexApi -----
   "profile transmit save \"" + profile_name.Replace("*","") + "\""
   "profile transmit create \"" + profile_name.Replace("*", "") + "\""
   "profile transmit reset \"" + profile_name.Replace("*", "") + "\""
   "profile transmit delete \"" + profile_name.Replace("*", "") + "\""
   "profile mic delete \"" + profile_name.Replace("*","") + "\""
   "profile mic save \"" + profile_name.Replace("*", "") + "\""
   "profile mic reset \"" + profile_name.Replace("*", "") + "\""
   "profile mic create \"" + profile_name.Replace("*", "") + "\""
   "profile global save \"" + profile_name + "\""
   "profile global delete \"" + profile_name + "\""
   
   "profile mic load \"" + _profileMICSelection + "\""
   "profile tx load \"" + _profileTXSelection + "\""
   "profile global load \"" + _profileGlobalSelection + "\""
   
   "profile global info"
   "profile tx info"
   "profile mic info"
   */
}
