//
//  SmartlinkParser.swift
//  FlexApiFeature/Listener
//
//  Created by Douglas Adams on 12/10/21.
//

import Foundation

import SharedFeature
import XCGLogFeature

extension SmartlinkListener {
  // ------------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Parse a Vita payload
  /// - Parameter text:   a Vita payload
  func parseVitaPayload(_ text: String) {
    enum Property: String {
      case application
      case radio
      case Received
    }
    let msg = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    let properties = msg.keyValuesArray()
    
    // Check for unknown properties
    guard let token = Property(rawValue: properties[0].key)  else {
      // log it
      log("Smartlink Listener: \(msg)", .warning, #function, #file, #line)
      return
    }
    // which primary message type?
    switch token {
      
    case .application:    parseApplication(Array(properties.dropFirst()))
    case .radio:          parseRadio(Array(properties.dropFirst()), msg: msg)
    case .Received:       break   // ignore message on Test connection
    }
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse a received "application" message
  /// - Parameter properties:        message KeyValue pairs
  private func parseApplication(_ properties: KeyValuesArray) {
    enum Property: String {
      case info
      case registrationInvalid = "registration_invalid"
      case userSettings        = "user_settings"
    }
    
    // Check for unknown properties
    guard let token = Property(rawValue: properties[0].key)  else {
      // log it and ignore the message
      log("Smartlink Listener: unknown application property, \(properties[1].key)", .warning, #function, #file, #line)
      return
    }
    switch token {
      
    case .info:                     parseApplicationInfo(Array(properties.dropFirst()))
    case .registrationInvalid:      parseRegistrationInvalid(properties)
    case .userSettings:             parseUserSettings(Array(properties.dropFirst()))
    }
  }
  
  /// Parse a received "radio" message
  /// - Parameter msg:        the message (after the primary type)
  private func parseRadio(_ properties: KeyValuesArray, msg: String) {
    enum Property: String {
      case connectReady   = "connect_ready"
      case list
      case testConnection = "test_connection"
    }

    // Check for unknown properties
    guard let token = Property(rawValue: properties[0].key)  else {
      // log it and ignore the message
      log("Smartlink Listener: unknown radio property, \(properties[1].key)", .warning, #function, #file, #line)
      return
    }
    // which secondary message type?
    switch token {
      
    case .connectReady:
      parseRadioConnectReady(Array(properties.dropFirst()))
    case .list:               parseRadioList(msg.dropFirst(11))
    case .testConnection:     parseTestConnectionResults(Array(properties.dropFirst()))
    }
  }
  
  /// Parse a received "application" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseApplicationInfo(_ properties: KeyValuesArray) {
    enum Property: String {
      case publicIp = "public_ip"
    }

    log("Smartlink Listener: ApplicationInfo received", .debug, #function, #file, #line)

    // process each key/value pair, <key=value>
    for property in properties {
      // Check for unknown properties
      guard let token = Property(rawValue: property.key)  else {
        // log it and ignore the Key
        log("Smartlink Listener: unknown info property, \(property.key)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .publicIp:       _publicIp = property.value
      }
      if _publicIp != nil {
        // stream it

        // NOTE:
//        Task {
        _listenerModel.statusUpdate(WanStatus(.publicIp, _firstName! + " " + _lastName!, _callsign!, _serial, _wanHandle, _publicIp))
//        }
      }
    }
  }
  
  /// Respond to an Invalid registration
  /// - Parameter msg:                the message text
  private func parseRegistrationInvalid(_ properties: KeyValuesArray) {
        log("Smartlink Listener: invalid registration: \(properties.count == 3 ? properties[2].key : "")", .warning, #function, #file, #line)
  }
  
  /// Parse a received "user settings" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseUserSettings(_ properties: KeyValuesArray) {
    enum Property: String {
      case callsign
      case firstName    = "first_name"
      case lastName     = "last_name"
    }

    log("Smartlink Listener: UserSettings received", .debug, #function, #file, #line)

    // process each key/value pair, <key=value>
    for property in properties {
      // Check for Unknown properties
      guard let token = Property(rawValue: property.key)  else {
        // log it and ignore the Key
        log("Smartlink Listener: unknown user setting, \(property.key)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .callsign:       _callsign = property.value
      case .firstName:      _firstName = property.value
      case .lastName:       _lastName = property.value
      }
    }
    
    if _firstName != nil && _lastName != nil && _callsign != nil {
      // NOTE:
//      Task {
      _listenerModel.statusUpdate(WanStatus(.settings, _firstName! + " " + _lastName!, _callsign!, _serial, _wanHandle, _publicIp))
//      }
    }
  }
  
  /// Parse a received "connect ready" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseRadioConnectReady(_ properties: KeyValuesArray) {
    enum Property: String {
      case handle
      case serial
    }

    log("Smartlink Listener: ConnectReady received", .debug, #function, #file, #line)

    // process each key/value pair, <key=value>
    for property in properties {
      // Check for unknown properties
      guard let token = Property(rawValue: property.key)  else {
        // log it and ignore the Key
        log("Smartlink Listener: unknown connect property, \(property.key)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .handle:         _wanHandle = property.value
      case .serial:         _serial = property.value
      }
    }
    // return to the waiting caller
    if _wanHandle != nil && _serial != nil {
      awaitWanHandle?.resume(returning: _wanHandle!)
    } else {
      awaitWanHandle?.resume(throwing: ListenerError.wanConnect)
    }
  }
  
  /// Parse a received "radio list" message
  /// - Parameter msg:        the list
  private func parseRadioList(_ msg: String.SubSequence) {
    var publicTlsPortToUse: Int?
    var publicUdpPortToUse: Int?
    var packet: Packet
    
    // several radios are possible, separate list into its components
    let radioMessages = msg.components(separatedBy: "|")
    
    for message in radioMessages where message != "" {
      packet = Packet.populate( message.keyValuesArray() )
      // now continue to fill the radio parameters
      // favor using the manually defined forwarded ports if they are defined
      if let tlsPort = packet.publicTlsPort, let udpPort = packet.publicUdpPort {
        publicTlsPortToUse = tlsPort
        publicUdpPortToUse = udpPort
        packet.isPortForwardOn = true;
      } else if (packet.upnpSupported) {
        publicTlsPortToUse = packet.publicUpnpTlsPort!
        publicUdpPortToUse = packet.publicUpnpUdpPort!
        packet.isPortForwardOn = false
      }
      
      if ( !packet.upnpSupported && !packet.isPortForwardOn ) {
        /* This will require extra negotiation that chooses
         * a port for both sides to try
         */
        // TODO: We also need to check the NAT for preserve_ports coming from radio here
        // if the NAT DOES NOT preserve ports then we can't do hole punch
        packet.requiresHolePunch = true
      }
      packet.publicTlsPort = publicTlsPortToUse
      packet.publicUdpPort = publicUdpPortToUse
      if let localAddr = _tcpSocket.localHost {
        packet.localInterfaceIP = localAddr
      }
      packet.source = .smartlink
      // add packet to Packets
      let newPacket = packet

      Task { await Discovery.shared.process(newPacket) }

      log("Smartlink Listener: RadioList RECEIVED, \(packet.nickname)", .debug, #function, #file, #line)
    }
  }
  
  /// Parse a received "test results" message
  /// - Parameter properties:         a KeyValuesArray
  private func parseTestConnectionResults(_ properties: KeyValuesArray) {
    enum Property: String {
      case forwardTcpPortWorking = "forward_tcp_port_working"
      case forwardUdpPortWorking = "forward_udp_port_working"
      case natSupportsHolePunch  = "nat_supports_hole_punch"
      case radioSerial           = "serial"
      case upnpTcpPortWorking    = "upnp_tcp_port_working"
      case upnpUdpPortWorking    = "upnp_udp_port_working"
    }
    
    var result = SmartlinkTestResult()
    
    // process each key/value pair, <key=value>
    for property in properties {
      // Check for unknown properties
      guard let token = Property(rawValue: property.key)  else {
        // log it and ignore the Key
        log("Smartlink Listener: unknown testConnection property, \(property.key)", .warning, #function, #file, #line)
        continue
      }
      
      // Known tokens, in alphabetical order
      switch token {
        
      case .forwardTcpPortWorking:      result.forwardTcpPortWorking = property.value.tValue
      case .forwardUdpPortWorking:      result.forwardUdpPortWorking = property.value.tValue
      case .natSupportsHolePunch:       result.natSupportsHolePunch = property.value.tValue
      case .radioSerial:                result.radioSerial = property.value
      case .upnpTcpPortWorking:         result.upnpTcpPortWorking = property.value.tValue
      case .upnpUdpPortWorking:         result.upnpUdpPortWorking = property.value.tValue
      }
      
      Task { [newResult = result] in
        await MainActor.run {
          _listenerModel.smartlinkTestResult = newResult
        }
      }
    }
    // log the result
    log("Smartlink Listener: Test result received, \(result.success ? "SUCCESS" : "FAILURE")", result.success ? .debug : .warning, #function, #file, #line)
  }
}
