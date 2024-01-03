//
//  GuiClient.swift
//  SharedFeatures/Shared
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation

public enum ClientEventAction: String {
  case added
  case removed
  case completed
}
public struct ClientEvent {
//public struct ClientEvent: Equatable {
  
  public init(_ action: ClientEventAction, client: GuiClient) {
    self.action = action
    self.client = client
  }
  public var action: ClientEventAction
  public var client: GuiClient
}

@Observable
final public class GuiClient: Identifiable {
//public struct GuiClient: Equatable, Identifiable {

  public init(handle: UInt32, station: String = "", program: String = "",
              clientId: String? = nil, host: String? = nil, ip: String? = nil,
              isLocalPtt: Bool = false, isThisClient: Bool = false) {
    
    self.handle = handle
    self.clientId = clientId
    self.host = host
    self.ip = ip
    self.isLocalPtt = isLocalPtt
    self.isThisClient = isThisClient
    self.program = program
    self.station = station
  }
  public var id: UInt32 { handle }
  
  public var clientId: String?
  public var handle: UInt32
  public var host: String?
  public var ip: String?
  public var isLocalPtt = false
  public var isThisClient = false
  public var program = ""
  public var station = ""
}
