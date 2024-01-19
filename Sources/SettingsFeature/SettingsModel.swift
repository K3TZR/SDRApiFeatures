//
//  SettingsModel.swift
//
//
//  Created by Douglas Adams on 1/19/24.
//

import Foundation
import SwiftUI

import SharedFeature

@Observable
final public class SettingsModel {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = SettingsModel()
  
  private init() {
    // have the UserDefaults been populated?
    if UserDefaults.standard.string(forKey: "isFirstUse") == nil {
      
      // NO, populate with default values
      UserDefaults.standard.set("NO", forKey: "isFirstUse")
      UserDefaults.standard.set(alertOnError, forKey: "alertOnError")
      UserDefaults.standard.set(clearOnSend, forKey: "clearOnSend")
      UserDefaults.standard.set(clearOnStart, forKey: "clearOnStart")
      UserDefaults.standard.set(clearOnStop, forKey: "clearOnStop")
      UserDefaults.standard.set(commandToSend, forKey: "commandToSend")
      UserDefaults.standard.set(commandsArray, forKey: "commandsArray")
      UserDefaults.standard.set(commandsIndex, forKey: "commandsIndex")
      UserDefaults.standard.set(fontSize, forKey: "fontSize")
      UserDefaults.standard.set(gotoTop, forKey: "gotoTop")
      UserDefaults.standard.set(guiDefault, forKey: "guiDefault")
      UserDefaults.standard.set(isGui, forKey: "isGui")
      UserDefaults.standard.set(directEnabled, forKey: "directEnabled")
      UserDefaults.standard.set(directGuiIp, forKey: "directGuiIp")
      UserDefaults.standard.set(directNonGuiIp, forKey: "directNonGuiIp")
      UserDefaults.standard.set(localEnabled, forKey: "localEnabled")
      UserDefaults.standard.set(loginRequired, forKey: "loginRequired")
      UserDefaults.standard.set(lowBandwidthDax, forKey: "lowBandwidthDax")
      UserDefaults.standard.set(messageFilter.rawValue, forKey: "messageFilter")
      UserDefaults.standard.set(messageFilterText, forKey: "messageFilterText")
      UserDefaults.standard.set(mtuValue, forKey: "mtuValue")
      UserDefaults.standard.set(nonGuiDefault, forKey: "nonGuiDefault")
      UserDefaults.standard.set(objectFilter.rawValue, forKey: "objectFilter")
      UserDefaults.standard.set(previousCommand, forKey: "previousCommand")
      UserDefaults.standard.set(remoteRxAudioCompressed, forKey: "remoteRxAudioComprsed")
      UserDefaults.standard.set(remoteRxAudioEnabled, forKey: "remoteRxAudioEnabled")
      UserDefaults.standard.set(remoteTxAudioEnabled, forKey: "remoteTxAudioEnabled")
      UserDefaults.standard.set(showPings, forKey: "showPings")
      UserDefaults.standard.set(showTimes, forKey: "showTimes")
      UserDefaults.standard.set(smartlinkEnabled, forKey: "smartlinkEnabled")
      UserDefaults.standard.set(smartlinkIdToken, forKey: "smartlinkIdToken")
      UserDefaults.standard.set(smartlinkUser, forKey: "smartlinkUser")
      UserDefaults.standard.set(station, forKey: "station")
      UserDefaults.standard.set(useDefault, forKey: "useDefault")
    } else {
      
      // YES, retrieve from standard User Defaults
      alertOnError = UserDefaults.standard.bool(forKey: "alertOnError")
      clearOnSend = UserDefaults.standard.bool(forKey: "clearOnSend")
      clearOnStart = UserDefaults.standard.bool(forKey: "clearOnStart")
      clearOnStop = UserDefaults.standard.bool(forKey: "clearOnStop")
      commandToSend = UserDefaults.standard.string(forKey: "commandToSend") ?? ""
      commandsArray = (UserDefaults.standard.object(forKey: "commandsArray") ?? [String]()) as! [String]
      commandsIndex = UserDefaults.standard.integer(forKey: "commandsIndex")
      fontSize = UserDefaults.standard.integer(forKey: "fontSize")
      fontSize = fontSize > 12 || fontSize < 8 ? 12 : fontSize
      gotoTop = UserDefaults.standard.bool(forKey: "gotoTop")
      guiDefault = UserDefaults.standard.string(forKey: "guiDefault")
      isGui = UserDefaults.standard.bool(forKey: "isGui")
      directEnabled = UserDefaults.standard.bool(forKey: "directEnabled")
      directGuiIp = UserDefaults.standard.string(forKey: "directGuiIp") ?? ""
      directNonGuiIp = UserDefaults.standard.string(forKey: "directNonGuiIP") ?? ""
      localEnabled = UserDefaults.standard.bool(forKey: "localEnabled")
      loginRequired = UserDefaults.standard.bool(forKey: "loginRequired")
      lowBandwidthDax = UserDefaults.standard.bool(forKey: "lowBandwidthDax")
      messageFilter = MessageFilter(rawValue: UserDefaults.standard.string(forKey: "messageFilter") ?? "all") ?? .all
      messageFilterText = UserDefaults.standard.string(forKey: "messageFilterText") ?? ""
      mtuValue = UserDefaults.standard.integer(forKey: "mtuValue")
      mtuValue = mtuValue > 1300 || mtuValue < 1000 ? 1300 : mtuValue
      nonGuiDefault = UserDefaults.standard.string(forKey: "nonGuiDefault")
      objectFilter = ObjectFilter(rawValue: UserDefaults.standard.string(forKey: "objectFilter") ?? "core") ?? .core
      previousCommand = UserDefaults.standard.string(forKey: "previousCommand") ?? ""
      remoteRxAudioCompressed = UserDefaults.standard.bool(forKey: "remoteRxAudioCompressed")
      remoteRxAudioEnabled = UserDefaults.standard.bool(forKey: "remoteRxAudioEnabled")
      remoteTxAudioEnabled = UserDefaults.standard.bool(forKey: "remoteTxAudioEnabled")
      showPings = UserDefaults.standard.bool(forKey: "showPings")
      showTimes = UserDefaults.standard.bool(forKey: "showTimes")
      smartlinkEnabled = UserDefaults.standard.bool(forKey: "smartlinkEnabled")
      smartlinkIdToken = UserDefaults.standard.string(forKey: "smartlinkIdToken")
      station = UserDefaults.standard.string(forKey: "station") ?? "SDRApi"
      useDefault = UserDefaults.standard.bool(forKey: "useDefault")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  var alertOnError: Bool = false          { didSet{ UserDefaults.standard.set(alertOnError, forKey: "alertOnError") }}
  var clearOnSend: Bool = false           { didSet{ UserDefaults.standard.set(clearOnSend, forKey: "clearOnSend") }}
  var clearOnStart: Bool = true           { didSet{ UserDefaults.standard.set(clearOnStart, forKey: "clearOnStart") }}
  var clearOnStop: Bool = false           { didSet{ UserDefaults.standard.set(clearOnStop, forKey: "clearOnStop") }}
  var commandToSend = ""                  { didSet{ UserDefaults.standard.set(commandToSend, forKey: "commandToSend") }}
  var commandsArray = [""]                { didSet{ UserDefaults.standard.set(commandsArray, forKey: "commandsArray") }}
  var commandsIndex = 0                   { didSet{ UserDefaults.standard.set(commandsIndex, forKey: "commandsIndex") }}
  var fontSize = 12                       { didSet{ UserDefaults.standard.set(fontSize, forKey: "fontSize") }}
  var gotoTop: Bool = false               { didSet{ UserDefaults.standard.set(gotoTop, forKey: "gotoTop") }}
  var guiDefault: String?                 { didSet{ UserDefaults.standard.set(guiDefault, forKey: "guiDefault") }}
  var isGui: Bool = true                  { didSet{ UserDefaults.standard.set(isGui, forKey: "isGui") }}
  var directEnabled: Bool = false         { didSet{ UserDefaults.standard.set(directEnabled, forKey: "directEnabled") }}
  var directGuiIp = ""                    { didSet{ UserDefaults.standard.set(directGuiIp, forKey: "directGuiIp") }}
  var directNonGuiIp = ""                 { didSet{ UserDefaults.standard.set(directNonGuiIp, forKey: "directNonGuiIp") }}
  var localEnabled: Bool = true           { didSet{ UserDefaults.standard.set(localEnabled, forKey: "localEnabled") }}
  var loginRequired: Bool = false         { didSet{ UserDefaults.standard.set(loginRequired, forKey: "loginRequired") }}
  var lowBandwidthDax: Bool = false       { didSet{ UserDefaults.standard.set(lowBandwidthDax, forKey: "lowBandwidthDax") }}
  var messageFilter: MessageFilter = .all { didSet{ UserDefaults.standard.set(messageFilter.rawValue, forKey: "messageFilter") }}
  var messageFilterText = ""              { didSet{ UserDefaults.standard.set(messageFilterText, forKey: "messageFilterText") }}
  var mtuValue = 1300                     { didSet{ UserDefaults.standard.set(mtuValue, forKey: "mtuValue") }}
  var nonGuiDefault: String?              { didSet{ UserDefaults.standard.set(nonGuiDefault, forKey: "nonGuiDefault") }}
  var objectFilter: ObjectFilter = .coreNoMeters  { didSet{ UserDefaults.standard.set(objectFilter.rawValue, forKey: "objectFilter") }}
  var previousCommand = ""                { didSet{ UserDefaults.standard.set(previousCommand, forKey: "previousCommand") }}
  var remoteRxAudioCompressed = true      { didSet{ UserDefaults.standard.set(remoteRxAudioCompressed, forKey: "remoteRxAudioCompressed") }}
  var remoteRxAudioEnabled: Bool = false  { didSet{ UserDefaults.standard.set(remoteRxAudioEnabled, forKey: "remoteRxAudioEnabled") }}
  var remoteTxAudioEnabled: Bool = false  { didSet{ UserDefaults.standard.set(remoteTxAudioEnabled, forKey: "remoteTxAudioEnabled") }}
  var showPings: Bool = false             { didSet{ UserDefaults.standard.set(showPings, forKey: "showPings") }}
  var showTimes: Bool = true              { didSet{ UserDefaults.standard.set(showTimes, forKey: "showTimes") }}
  var smartlinkEnabled: Bool = false      { didSet{ UserDefaults.standard.set(smartlinkEnabled, forKey: "smartlinkEnabled") }}
  var smartlinkIdToken: String?           { didSet{ UserDefaults.standard.set(smartlinkIdToken, forKey: "smartlinkIdToken") }}
  var smartlinkUser = ""                  { didSet{ UserDefaults.standard.set(smartlinkUser, forKey: "smartlinkUser") }}
  var station = "SDRApi"                  { didSet{ UserDefaults.standard.set(station, forKey: "station") }}
  var useDefault: Bool = false            { didSet{ UserDefaults.standard.set(useDefault, forKey: "useDefault") }}
}
