//
//  ApiModel+Tcp.swift
//  
//
//  Created by Douglas Adams on 5/24/23.
//

import Foundation

import SharedFeature
import TcpFeature

extension ApiModel {
  // ----------------------------------------------------------------------------
  // MARK: - Tcp connection
  
  /// Connect to a Radio
  /// - Parameter params:     a struct of parameters
  /// - Returns:              success / failure
  func connect(_ packet: Packet) -> Bool {
    return Tcp.shared.connect(packet.source == .smartlink,
                              packet.requiresHolePunch,
                              packet.negotiatedHolePunchPort,
                              packet.publicTlsPort,
                              packet.port,
                              packet.publicIp,
                              packet.localInterfaceIP)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Tcp Subscriptions
  
  /// Process the AsyncStream of inbound TCP messages
  func subscribeToMessages()  {
    Task(priority: .high) {
      log("ApiModel: TcpMessage subscription STARTED", .debug, #function, #file, #line)
      for await tcpMessage in Tcp.shared.inboundMessagesStream {
        tcpInbound(tcpMessage.text)
      }
      log("ApiModel: TcpMessage subscription STOPPED", .debug, #function, #file, #line)
    }
  }

  /// Process the AsyncStream of TCP status changes
//  func subscribeToTcpStatus() {
//    Task(priority: .high) {
//      log("Api: TcpStatus subscription STARTED", .debug, #function, #file, #line)
//      for await status in Tcp.shared.statusStream {
//        tcpStatus(status)
//      }
//      log("Api: TcpStatus subscription STOPPED", .debug, #function, #file, #line)
//    }
//  }
//
//  private func tcpStatus(_ status: TcpStatus) {
//    switch status.statusType {
//
//    case .didConnect:
//      log("Tcp: socket connected to \(status.host) on port \(status.port)", .debug, #function, #file, #line)
//    case .didSecure:
//      log("Tcp: TLS socket did secure", .debug, #function, #file, #line)
//    case .didDisconnect:
//      log("Tcp: socket disconnected \(status.reason ?? "User initiated"), \(status.error == nil ? "" : "with error \(status.error!.localizedDescription)")", status.error == nil ? .debug : .warning, #function, #file, #line)
//
////      Task { await MainActor.run { disconnect(status.reason) }}
//    }
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Tcp Parse methods
  
  private func tcpInbound(_ message: String) {
    // pass to the Tester (if any)
    //    _testerDelegate?.tcpInbound(message)
    
    // switch on the first character of the text
    switch message.prefix(1) {
      
    case "H", "h":  connectionHandle = String(message.dropFirst()).handle ; log("Api: connectionHandle = \(connectionHandle?.hex ?? "missing")", .debug, #function, #file, #line)
    case "M", "m":  parseMessage( message.dropFirst() )
    case "R", "r":  parseReply( message )
    case "S", "s":  parseStatus( message.dropFirst() )
    case "V", "v":  Task { await MainActor.run { radio?.hardwareVersion = String(message.dropFirst()) }}
    default:        log("ApiModel: unexpected message = \(message)", .warning, #function, #file, #line)
    }
  }

  /// Parse a Message.
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  private func parseMessage(_ msg: Substring) {
    // separate it into its components
    let components = msg.components(separatedBy: "|")
    
    // ignore incorrectly formatted messages
    if components.count < 2 {
      log("ApiModel: incomplete message = c\(msg)", .warning, #function, #file, #line)
      return
    }
    let msgText = components[1]
    
    // log it
    log("ApiModel: message = \(msgText)", flexErrorLevel(errorCode: components[0]), #function, #file, #line)
    
    // FIXME: Take action on some/all errors?
  }
  
  /// Parse Replies
  /// - Parameters:
  ///   - commandSuffix:      a Reply Suffix
  private func parseReply(_ message: String) {
    
    let replySuffix = message.dropFirst()
    
    // separate it into its components
    let components = replySuffix.components(separatedBy: "|")
    // ignore incorrectly formatted replies
    if components.count < 2 {
      log("ApiModel: incomplete reply, r\(replySuffix)", .warning, #function, #file, #line)
      return
    }
    
    // get the sequence number, reply and any additional data
    let seqNum = components[0].sequenceNumber
    let reply = components[1]
    let suffix = components.count < 3 ? "" : components[2]
    
    // is the sequence number in the reply handlers?
    //    if let replyTuple = ObjectModel.shared.replyHandlers[ seqNum ] {
    if let replyTuple = replyHandlers[ seqNum ] {
      // YES
      let command = replyTuple.command

      // Remove the object from the notification list
      removeReplyHandler(components[0].sequenceNumber)

      // Anything other than kNoError is an error, log it and ignore the Reply
      guard reply == kNoError else {
        // ignore non-zero reply from "client program" command
        if !command.hasPrefix("client program ") {
          log("ApiModel: reply >\(reply)<, to c\(seqNum), \(command), \(flexErrorString(errorCode: reply)), \(suffix)", .error, #function, #file, #line)
        }
        return
      }
      
      // process replies to the internal "sendCommands"?
      switch command {

//      case "client gui":    parseGuiReply(suffix)     // pointless since I always send a clientId
      case "slice list":    parseSliceListReply(suffix)
      case "ant list":      parseAntListReply(suffix)
      case "info":          parseInfoReply(suffix)
      case "mic list":      parseMicListReply(suffix)
      case "radio uptime":  parseUptimeReply(suffix)
      case "version":       parseVersionReply(suffix)

      default: break
      }
      
      // did the replyTuple include a continuation?
//      if let continuation = replyTuple.continuation {
//        // YES, resume it
//        if reply == kNoError {
//          continuation.resume(returning: suffix)
//        } else {
//          continuation.resume(throwing: ApiError.replyError)
//        }
//      }
      
      // did the replyTuple include a callback?
      if let handler = replyTuple.replyTo {
        // YES, call the sender's Handler
        handler(command, seqNum, reply, suffix)
      }
    } else {
      log("ApiModel: reply >\(reply)<, unknown sequence number c\(seqNum), \(flexErrorString(errorCode: reply)), \(suffix)", .error, #function, #file, #line)
    }
  }
  
  /// Parse a Status
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  private func parseStatus(_ commandSuffix: Substring) {
    
    // separate it into its components ( [0] = <apiHandle>, [1] = <remainder> )
    let components = commandSuffix.components(separatedBy: "|")
    
    // ignore incorrectly formatted status
    guard components.count > 1 else {
      log("ApiModel: incomplete status = c\(commandSuffix)", .warning, #function, #file, #line)
      return
    }
    
    // find the space & get the msgType
    let spaceIndex = components[1].firstIndex(of: " ")!
    let statusType = String(components[1][..<spaceIndex])
    
    // everything past the msgType is in the remainder
    let messageIndex = components[1].index(after: spaceIndex)
    let statusMessage = String(components[1][messageIndex...])
    
    // Check for unknown Object Types
    guard let objectType = ObjectType(rawValue: statusType)  else {
      // log it and ignore the message
      log("ApiModel: unknown status token = \(statusType)", .warning, #function, #file, #line)
      return
    }
    
    // is this status message the first for our handle?
    if firstStatusMessageReceived == false && components[0].handle == connectionHandle {
      // YES, set the API state to finish the UDP initialization
      firstStatusMessageReceived = true
      _awaitFirstStatusMessage!.resume()
    }
    
    if objectType == .stream {
      parse(statusMessage)
    } else {
      Task { await parse(objectType, statusMessage) }
    }
  }
  
  /// Parse the Reply to a Client Gui command
  /// - Parameters:
  ///   - suffix:          a reply string
//  @MainActor private func parseGuiReply(_ suffix: String) {
//    log("ApiModel: client gui response = \(suffix)", .debug, #function, #file, #line)
//  }

  /// Parse the Reply to a Slice LIst command
  /// - Parameters:
  ///   - suffix:          a reply string
  @MainActor private func parseSliceListReply(_ suffix: String) {
    // save the list
    sliceList = suffix.valuesArray().compactMap { UInt32($0, radix: 10) }
  }

  /// Parse the Reply to a Ant LIst command
  /// - Parameters:
  ///   - suffix:          a reply string
  @MainActor private func parseAntListReply(_ suffix: String) {
    // save the list
    antList = suffix.valuesArray( delimiter: "," )
  }

  /// Parse the Reply to a Mic LIst command
  /// - Parameters:
  ///   - suffix:          a reply string
  @MainActor private func parseMicListReply(_ suffix: String) {
    // save the list
    micList = suffix.valuesArray(  delimiter: "," )
  }

  /// Parse the Reply to a Uptime command
  /// - Parameters:
  ///   - suffix:          a reply string
  @MainActor private func parseUptimeReply(_ suffix: String) {
    // save the list
    uptime = Int(suffix) ?? 0 
  }

  /// Parse the Reply to an Info command
  /// - Parameters:
  ///   - suffix:          a reply string
  @MainActor private func parseInfoReply(_ suffix: String) {
    enum Property: String {
        case atuPresent               = "atu_present"
        case callsign
        case chassisSerial            = "chassis_serial"
        case gateway
        case gps
        case ipAddress                = "ip"
        case location
        case macAddress               = "mac"
        case model
        case netmask
        case name
        case numberOfScus             = "num_scu"
        case numberOfSlices           = "num_slice"
        case numberOfTx               = "num_tx"
        case options
        case region
        case screensaver
        case softwareVersion          = "software_ver"
    }
      // process each key/value pair, <key=value>
    for property in suffix.replacingOccurrences(of: "\"", with: "").keyValuesArray(delimiter: ",") {
          // check for unknown Keys
          guard let token = Property(rawValue: property.key) else {
              // log it and ignore the Key
              log("ApiModel: unknown info token, \(property.key) = \(property.value)", .warning, #function, #file, #line)
              continue
          }
          // Known keys, in alphabetical order
          switch token {
          
          case .atuPresent:       atuPresent = property.value.bValue
          case .callsign:         callsign = property.value
          case .chassisSerial:    chassisSerial = property.value
          case .gateway:          gateway = property.value
          case .gps:              gpsPresent = (property.value != "Not Present")
          case .ipAddress:        ipAddress = property.value
          case .location:         location = property.value
          case .macAddress:       macAddress = property.value
          case .model:            radioModel = property.value
          case .netmask:          netmask = property.value
          case .name:             nickname = property.value
          case .numberOfScus:     numberOfScus = property.value.iValue
          case .numberOfSlices:   numberOfSlices = property.value.iValue
          case .numberOfTx:       numberOfTx = property.value.iValue
          case .options:          radioOptions = property.value
          case .region:           region = property.value
          case .screensaver:      radioScreenSaver = property.value
          case .softwareVersion:  softwareVersion = property.value
          }
      }
  }

  /// Parse the Reply to a Version command, reply format: <key=value>#<key=value>#...<key=value>
  /// - Parameters:
  ///   - suffix:          a reply string
  @MainActor private func parseVersionReply(_ suffix: String) {
    enum Property: String {
      case fpgaMb                   = "fpga-mb"
      case psocMbPa100              = "psoc-mbpa100"
      case psocMbTrx                = "psoc-mbtrx"
      case smartSdrMB               = "smartsdr-mb"
      case picDecpu                 = "pic-decpu"
    }
    // process each key/value pair, <key=value>
    for property in suffix.keyValuesArray(delimiter: "#") {
      // check for unknown Keys
      guard let token = Property(rawValue: property.key) else {
        // log it and ignore the Key
        log("ApiModel: unknown version property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known tokens, in alphabetical order
      switch token {
        
      case .smartSdrMB:   smartSdrMB = property.value
      case .picDecpu:     picDecpuVersion = property.value
      case .psocMbTrx:    psocMbtrxVersion = property.value
      case .psocMbPa100:  psocMbPa100Version = property.value
      case .fpgaMb:       fpgaMbVersion = property.value
      }
    }
  }
  
//  public func altAntennaName(for stdName: String) -> String {
//    // return alternate name (if any)
//    for antenna in settingsModel.altAntennaNames where antenna.stdName == stdName {
//      return antenna.customName
//    }
//    return stdName
//  }
//  
//  public func altAntennaName(for stdName: String, _ customName: String) {
//    for (i, antenna) in settingsModel.altAntennaNames.enumerated() where antenna.stdName == stdName {
//      settingsModel.altAntennaNames[i].customName = customName
//      let oldAntList = antList
//      antList = oldAntList
//      return
//    }
//    settingsModel.altAntennaNames.append(Settings.AntennaName(stdName: stdName, customName: customName))
//    let oldAntList = antList
//    antList = oldAntList
//  }
  
//  public func altAntennaNameRemove(for stdName: String) {
//    for (i, antenna) in altAntennaList.enumerated() where antenna.stdName == stdName {
//      altAntennaList.remove(at: i)
//    }
//  }

}
