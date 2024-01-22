//
//  SettingsModel.swift
//  
//
//  Created by Douglas Adams on 1/20/24.
//

import SwiftUI

import SharedFeature

@Observable
public class SettingsModel {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton

  public static var shared = SettingsModel()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var alertOnError: Bool
  public var clearOnSend: Bool
  public var clearOnStart: Bool
  public var clearOnStop: Bool
  public var commandToSend: String
  public var commandsArray: [String]
  public var commandsIndex: Int
  public var fontSize: Int
  public var gotoTop: Bool
  public var guiDefault: String?
  public var isGui: Bool
  public var directEnabled: Bool
  public var directGuiIp: String
  public var directNonGuiIp: String
  public var localEnabled: Bool
  public var loginRequired: Bool
  public var lowBandwidthDax: Bool
  public var messageFilter: MessageFilter
  public var messageFilterText: String
  public var mtuValue: Int
  public var nonGuiDefault: String?
  public var objectFilter: ObjectFilter
  public var previousCommand: String
  public var remoteRxAudioCompressed: Bool
  public var remoteRxAudioEnabled: Bool
  public var remoteTxAudioEnabled: Bool
  public var showPings: Bool
  public var showTimes: Bool
  public var smartlinkEnabled: Bool
  public var smartlinkIdToken: String?
  public var smartlinkUser: String
  public var station = "SDRApi"
  public var useDefault: Bool

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private let AppDefaults = UserDefaults.standard
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  private init() {
        
    // first usage?
    if AppDefaults.bool(forKey: "initialized") == false {
      // YES, populate and save to UserDefaults
      alertOnError = true
      clearOnSend = true
      clearOnStart = true
      clearOnStop = false
      commandToSend = ""
      commandsArray = [String]()
      commandsIndex = 0
      fontSize = 12
      gotoTop = false
      guiDefault = nil
      isGui = true
      directEnabled = false
      directGuiIp = ""
      directNonGuiIp = ""
      localEnabled = true
      loginRequired = false
      lowBandwidthDax = false
      messageFilter = .all
      messageFilterText = ""
      mtuValue = 1_300
      nonGuiDefault = nil
      objectFilter = .coreNoMeters
      previousCommand = ""
      remoteRxAudioCompressed = false
      remoteRxAudioEnabled = false
      remoteTxAudioEnabled = false
      showPings = false
      showTimes = true
      smartlinkEnabled = false
      smartlinkIdToken = nil
      smartlinkUser = ""
      station = "SDRApi"
      useDefault = false
      
      save()
      
    } else {
      // NO, initialize from UserDefaults
      
      alertOnError = AppDefaults.bool(forKey: "alertOnError")
      clearOnSend = AppDefaults.bool(forKey: "clearOnSend")
      clearOnStart = AppDefaults.bool(forKey: "clearOnStart")
      clearOnStop = AppDefaults.bool(forKey: "clearOnStop")
      commandToSend = AppDefaults.string(forKey: "commandToSend") ?? ""
      commandsArray = AppDefaults.object(forKey: "commandsArray") as? [String] ?? [String]()
      commandsIndex = AppDefaults.integer(forKey: "commandsIndex")
      fontSize = AppDefaults.integer(forKey: "fontSize")
      gotoTop = AppDefaults.bool(forKey: "gotoTop")
      guiDefault = AppDefaults.string(forKey: "guiDefault") ?? nil
      isGui = AppDefaults.bool(forKey: "isGui")
      directEnabled = AppDefaults.bool(forKey: "directEnabled")
      directGuiIp = AppDefaults.string(forKey: "directGuiIp") ?? ""
      directNonGuiIp = AppDefaults.string(forKey: "directNonGuiIp") ?? ""
      localEnabled = AppDefaults.bool(forKey: "localEnabled")
      loginRequired = AppDefaults.bool(forKey: "loginRequired")
      lowBandwidthDax = AppDefaults.bool(forKey: "lowBandwidthDax")
      messageFilter = MessageFilter(rawValue: AppDefaults.string(forKey: "messageFilter") ?? "all") ?? .all
      messageFilterText = AppDefaults.string(forKey: "messageFilterText") ?? ""
      mtuValue = AppDefaults.integer(forKey: "mtuValue")
      nonGuiDefault = AppDefaults.string(forKey: "nonGuiDefault") ?? nil
      objectFilter = ObjectFilter(rawValue: AppDefaults.string(forKey: "objectFilter") ?? "coreNoMeters") ?? .coreNoMeters
      previousCommand = AppDefaults.string(forKey: "previousCommand") ?? ""
      remoteRxAudioCompressed = AppDefaults.bool(forKey: "remoteRxAudioCompressed")
      remoteRxAudioEnabled = AppDefaults.bool(forKey: "remoteRxAudioEnabled")
      remoteTxAudioEnabled = AppDefaults.bool(forKey: "remoteTxAudioEnabled")
      showPings = AppDefaults.bool(forKey: "showPings")
      showTimes = AppDefaults.bool(forKey: "showTimes")
      smartlinkEnabled = AppDefaults.bool(forKey: "smartlinkEnabled")
      smartlinkIdToken = AppDefaults.string(forKey: "smartlinkIdToken") ?? nil
      smartlinkUser = AppDefaults.string(forKey: "smartlinkUser") ?? ""
//      station = "SDRApi"
      useDefault = AppDefaults.bool(forKey: "useDefault")
    }
  }
  
  // save to UserDefaults
  public func save() {
    // mark it as initialized
    AppDefaults.set(true, forKey: "initialized")
    
    AppDefaults.set(alertOnError, forKey: "alertOnError")
    AppDefaults.set(clearOnSend, forKey: "clearOnSend")
    AppDefaults.set(clearOnStart, forKey: "clearOnStart")
    AppDefaults.set(clearOnStop, forKey: "clearOnStop")
    AppDefaults.set(commandToSend, forKey: "commandToSend")
    AppDefaults.set(commandsArray, forKey: "commandsArray")
    AppDefaults.set(commandsIndex, forKey: "commandsIndex")
    AppDefaults.set(fontSize, forKey: "fontSize")
    AppDefaults.set(gotoTop, forKey: "gotoTop")
    AppDefaults.set(guiDefault, forKey: "guiDefault")
    AppDefaults.set(isGui, forKey: "isGui")
    AppDefaults.set(directEnabled, forKey: "directEnabled")
    AppDefaults.set(directGuiIp, forKey: "directGuiIp")
    AppDefaults.set(directNonGuiIp, forKey: "directNonGuiIp")
    AppDefaults.set(localEnabled, forKey: "localEnabled")
    AppDefaults.set(loginRequired, forKey: "loginRequired")
    AppDefaults.set(lowBandwidthDax, forKey: "lowBandwidthDax")
    AppDefaults.set(messageFilter.rawValue, forKey: "messageFilter")
    AppDefaults.set(messageFilterText, forKey: "messageFilterText")
    AppDefaults.set(mtuValue, forKey: "mtuValue")
    AppDefaults.set(nonGuiDefault, forKey: "nonGuiDefault")
    AppDefaults.set(objectFilter.rawValue,forKey: "objectFilter")
    AppDefaults.set(previousCommand, forKey: "previousCommand")
    AppDefaults.set(remoteRxAudioCompressed, forKey: "remoteRxAudioCompressed")
    AppDefaults.set(remoteRxAudioEnabled, forKey: "remoteRxAudioEnabled")
    AppDefaults.set(remoteTxAudioEnabled, forKey: "remoteTxAudioEnabled")
    AppDefaults.set(showPings, forKey: "showPings")
    AppDefaults.set(showTimes, forKey: "showTimes")
    AppDefaults.set(smartlinkEnabled, forKey: "smartlinkEnabled")
    AppDefaults.set(smartlinkIdToken, forKey: "smartlinkIdToken")
    AppDefaults.set(smartlinkUser, forKey: "smartlinkUser")
//    station = "SDRApi"
    AppDefaults.set(useDefault, forKey: "useDefault")
  }
}
