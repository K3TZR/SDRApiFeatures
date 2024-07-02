//
//  Api.swift
//  
//
//  Created by Douglas Adams on 4/11/23.
//

import ComposableArchitecture
import Foundation
import os

import ListenerFeature
import SharedFeature
import VitaFeature


@Observable
public final class ApiModel: TcpProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = ApiModel()
  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var activeSlice: Slice?
//  public private(set) var activeStation: String?
//  public var testMode = false
  public var testDelegate: TcpProcessor?


  public internal(set) var connectionHandle: UInt32?
  public internal(set) var hardwareVersion: String?

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _awaitFirstStatusMessage: CheckedContinuation<(), Never>?
  private var _awaitWanValidation: CheckedContinuation<String, Never>?
  private var _awaitClientIpValidation: CheckedContinuation<String, Never>?
  private var _firstStatusMessageReceived: Bool = false
  private var _guiClientId: String?
  private var _pinger: Pinger?
  private var _replyDictionary = ReplyDictionary()
  private var _wanHandle = ""

  private var _tcp = Tcp()
  private var _udp = Udp()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Connection methods

  /// Connect to a Radio
  /// - Parameters:
  ///   - packet: selected broadcast Packet
  ///   - station: selected Station
  ///   - isGui: true = GUI
  ///   - disconnectHandle: handle to another connection to be disconnected (if any)
  ///   - programName: program name
  ///   - mtuValue: max transport unit
  ///   - lowBandwidthDax: true = use low bw DAX
  ///   - lowBandwidthConnect: true = minimize connection bandwidth
  public func connect(packet: Packet?, station: String?, isGui: Bool, disconnectHandle: UInt32?, programName: String, mtuValue: Int, lowBandwidthDax: Bool = false, lowBandwidthConnect: Bool = false) async throws {
    
    if let packet, let station {
      Task { await MainActor.run {
//        MessagesModel.shared.startTime = Date()
        ObjectModel.shared.activePacket = packet
        ObjectModel.shared.activeStation = station
      }}
      
      // Instantiate a Radio
      try await MainActor.run{
        ObjectModel.shared.radio = Radio(packet, isGui)
        guard ObjectModel.shared.radio != nil else { throw ApiError.instantiation }
      }
//      log("ApiModel: Radio instantiated for \(packet.nickname), \(packet.source)", .debug, #function, #file, #line)
      apiLog.debug("ApiModel: Radio instantiated \(packet.nickname), \(packet.source.rawValue)")

      guard connect(using: packet) else { throw ApiError.connection }
      apiLog.debug("ApiModel: Tcp connection established")
            
      if disconnectHandle != nil {
        // pending disconnect
        sendTcp("client disconnect \(disconnectHandle!.hex)")
      }
      
      // wait for the first Status message with my handle
      try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [self] in
        await awaitFirstStatusMessage()
      }
      apiLog.debug("ApiModel: First status message received")
      
      // is this a Wan connection?
      if packet.source == .smartlink {
        // YES, send Wan Connect message & wait for the reply
        _wanHandle = try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [serial = packet.serial, negotiatedHolePunchPort = packet.negotiatedHolePunchPort] in
          try await ListenerModel.shared.smartlinkConnect(for: serial, holePunchPort: negotiatedHolePunchPort)
        }
        
        apiLog.debug("ApiModel: wanHandle received")
        
        // send Wan Validate & wait for the reply
        apiLog.debug("Api: Wan validate sent for handle=\(self._wanHandle)")
        sendTcp("wan validate handle=\(_wanHandle)", replyTo: wanValidationReplyHandler)
        let reply = try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [self] in
          //          _ = try await sendCommandAwaitReply("wan validate handle=\(_wanHandle)")
          //          await sendCommand("wan validate handle=\(_wanHandle), replyTo callback: awaitWanValidation")
          
          await wanValidation()
        }
        apiLog.debug("ApiModel: Wan validation = \(reply)")
      }
      // bind UDP
      let ports = _udp.bind(packet.source == .smartlink,
                                  packet.publicIp,
                                  packet.requiresHolePunch,
                                  packet.negotiatedHolePunchPort,
                                  packet.publicUdpPort)
      
      guard ports != nil else { _tcp.disconnect() ; throw ApiError.udpBind }
      apiLog.debug("ApiModel: UDP bound, receive port = \(ports!.0), send port = \(ports!.1)")
      
      // is this a Wan connection?
      if packet.source == .smartlink {
        // send Wan Register (no reply)
        sendUdp("client udp_register handle=" + connectionHandle!.hex )
        apiLog.debug("ApiModel: UDP registration sent")
        
        // send Client Ip & wait for the reply
        sendTcp("client ip", replyTo: ipReplyHandler)
        let reply = try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [self] in
          await clientIpValidation()
        }
        apiLog.debug("ApiModel: Client ip = \(reply)")
      }
      
      // send the initial commands
      sendInitialCommands(isGui, programName, station, mtuValue, lowBandwidthDax, lowBandwidthConnect)
      apiLog.info("ApiModel: initial commands sent (isGui = \(isGui))")
      
      startPinging()
      apiLog.debug("ApiModel: pinging \(packet.publicIp)")
      
      // set the UDP port for a Local connection
      if packet.source == .local {
        sendTcp("client udpport " + "\(_udp.sendPort)")
        apiLog.info("ApiModel: Client Udp port set to \(self._udp.sendPort)")
      }
    }
  }
  
  /// Disconnect the current Radio and remove all its objects / references
  /// - Parameter reason: an optional reason
  public func disconnect(_ reason: String? = nil) {
    if reason == nil {
      apiLog.debug("ApiModel: Disconnect, \((reason == nil ? "User initiated" : reason!))")
    }
    
    _firstStatusMessageReceived = false
    
    // stop pinging (if active)
    stopPinging()
    apiLog.debug("ApiModel: Pinging STOPPED")
    
    connectionHandle = nil
    
    // stop udp
    _udp.unbind()
    apiLog.debug("ApiModel: Disconnect, UDP unbound")
    
    _tcp.disconnect()
    
    Task { await MainActor.run {
      ObjectModel.shared.activePacket = nil
      ObjectModel.shared.activeStation = nil
    }
    }
    Task {
      await ObjectModel.shared.removeAllObjects()
      await _replyDictionary.removeAll()
    }
    apiLog.debug("ApiModel: Disconnect, Objects removed")
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public TCP message processor

  public func tcpProcessor(_ msg: String, isInput: Bool) {
    
    // received messages sent to the Tester
    if testDelegate != nil { Task { await MainActor.run { testDelegate!.tcpProcessor(msg, isInput: true) }}}
    
    // the first character indicates the type of message
    switch msg.prefix(1).uppercased() {
      
    case "H":  connectionHandle = String(msg.dropFirst()).handle ; apiLog.debug("Api: connectionHandle = \(self.connectionHandle?.hex ?? "missing")")
    case "M":  parseMessage( msg.dropFirst() )
    case "R":  defaultReplyProcessor( msg.dropFirst() )
    case "S":  parseStatus( msg.dropFirst() )
    case "V":  hardwareVersion = String(msg.dropFirst())
    default:   apiLog.warning("ApiModel: unexpected message = \(msg)")
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public Send methods

  /// Send a command to the Radio (hardware) via TCP
  /// - Parameters:
  ///   - command:        a Command String
  ///   - flag:           use "D"iagnostic form
  ///   - callback:       a callback function (if any)
  public func sendTcp(_ cmd: String, diagnostic: Bool = false, replyTo callback: ReplyHandler? = nil) {
    Task {
      // assign sequenceNumber & register to be notified when reply received
      let sequenceNumber = await _replyDictionary.add((replyTo: callback, command: cmd))
      
      // assemble the command
      let command =  "C" + "\(diagnostic ? "D" : "")" + "\(sequenceNumber)|" + cmd
      
      // tell TCP to send it
      _tcp.send(command + "\n", sequenceNumber)
      
      // sent messages sent to the Tester
      if testDelegate != nil { Task { await MainActor.run { testDelegate!.tcpProcessor(command, isInput: true) }}}
    }
  }
  
  /// Send data to the Radio (hardware) via UDP
  /// - Parameters:
  ///   - data: a Data
  public func sendUdp(_ data: Data) {
    // tell Udp to send the Data message
    _udp.send(data)
  }
  
  /// Send data to the Radio (hardware) via UDP
  /// - Parameters:
  ///   - string: a String
  public func sendUdp(_ string: String) {
    // tell Udp to send the String message
    _udp.send(string)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private connection methods

  /// Connect to a Radio
  /// - Parameter params:     a struct of parameters
  /// - Returns:              success / failure
  private func connect(using packet: Packet) -> Bool {
    return _tcp.connect(packet.source == .smartlink,
                              packet.requiresHolePunch,
                              packet.negotiatedHolePunchPort,
                              packet.publicTlsPort,
                              packet.port,
                              packet.publicIp,
                              packet.localInterfaceIP)
  }

  private func sendInitialCommands(_ isGui: Bool, _ programName: String, _ stationName: String, _ mtuValue: Int, _ lowBandwidthDax: Bool, _ lowBandwidthConnect: Bool) {
    @Shared(.appStorage("guiClientId")) var guiClientId = UUID().uuidString

    if isGui { sendTcp("client gui \(guiClientId)") }
    sendTcp("client program " + programName)
    if isGui { sendTcp("client station " + stationName) }
    if lowBandwidthConnect { setLowBandwidthConnect() }
    requestInfo(replyTo: initialCommandsReplyHandler)
    requestVersion(replyTo: initialCommandsReplyHandler)
    requestAntennaList(replyTo: initialCommandsReplyHandler)
    requestMicList(replyTo: initialCommandsReplyHandler)
    requestGlobalProfile()
    requestTxProfile()
    requestMicProfile()
    requestDisplayProfile()
    sendSubciptions()
    setMtuLimit(mtuValue)
    setLowBandwidthDax(lowBandwidthDax)
    requestUptime(replyTo: initialCommandsReplyHandler)
  }

  private func sendSubciptions(callback: ReplyHandler? = nil) {
    sendTcp("sub tx all")
    sendTcp("sub atu all")
    sendTcp("sub amplifier all")
    sendTcp("sub meter all")
    sendTcp("sub pan all")
    sendTcp("sub slice all")
    sendTcp("sub gps all")
    sendTcp("sub audio_stream all")
    sendTcp("sub cwx all")
    sendTcp("sub xvtr all")
    sendTcp("sub memories all")
    sendTcp("sub daxiq all")
    sendTcp("sub dax all")
    sendTcp("sub usb_cable all")
    sendTcp("sub tnf all")
    sendTcp("sub client all")
    //      send("sub spot all")    // TODO:
  }

  private func startPinging() {
    // tell the Radio to expect pings
    sendTcp("keepalive enable")
    // start pinging the Radio
    _pinger = Pinger(self)
  }

  private func stopPinging() {
    _pinger?.stopPinging()
    _pinger = nil
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private continuation methods

  private func awaitFirstStatusMessage() async {
    return await withCheckedContinuation{ continuation in
      _awaitFirstStatusMessage = continuation
      apiLog.debug("ApiModel: waiting for first status message")
    }
  }
  
  private func clientIpValidation() async -> (String) {
    return await withCheckedContinuation{ continuation in
      _awaitClientIpValidation = continuation
      apiLog.debug("Api: Client ip request sent")
    }
  }

  private func wanValidation() async -> (String) {
    return await withCheckedContinuation{ continuation in
      _awaitWanValidation = continuation
      apiLog.debug("Api: Wan validate sent for handle=\(self._wanHandle)")
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Reply methods

  /// Parse Replies
  /// - Parameters:
  ///   - commandSuffix:      a Reply Suffix
  private func defaultReplyProcessor(_ replySuffix: Substring) {
    
    // separate it into its components
    let components = replySuffix.components(separatedBy: "|")
    // ignore incorrectly formatted replies
    if components.count < 2 {
      apiLog.warning("ApiModel: incomplete reply, r\(replySuffix)")
      return
    }
    
    // get the sequence number, reply and any additional data
    let seqNum = components[0].sequenceNumber
    let reply = components[1]
    let suffix = components.count < 3 ? "" : components[2]
    
    // is the sequence number in the reply handlers?
    //    if let replyTuple = ObjectModel.shared.replyHandlers[ seqNum ] {
    Task {
      if let replyTuple = await _replyDictionary[ seqNum ] {
        // YES
        let command = replyTuple.command
        
        // Remove the object from the notification list
        await _replyDictionary.remove(components[0].sequenceNumber)
        
        //      removeReplyHandler(components[0].sequenceNumber)
        
        // Anything other than kNoError is an error, log it
        // ignore non-zero reply from "client program" command
        if reply != kNoError && !command.hasPrefix("client program ") {
          apiLog.error("ApiModel: reply >\(reply)<, to c\(seqNum), \(command), \(flexErrorString(errorCode: reply)), \(suffix)")
        }
        // did the replyTuple include a callback?
        if let handler = replyTuple.replyTo {
          // YES, call the sender's Handler
          handler(command, seqNum, reply, suffix)
        }
      } else {
        apiLog.error("ApiModel: \(replySuffix) reply >\(reply)<, unknown sequence number c\(seqNum), \(flexErrorString(errorCode: reply)), \(suffix)")
      }
    }
  }

  private func initialCommandsReplyHandler(_ command: String, _ seqNumber: Int, _ responseValue: String, _ reply: String) {
     var keyValues: KeyValuesArray
     let adjReply = reply.replacingOccurrences(of: "\"", with: "")
     
     // process replies to the internal "sendCommands"?
     switch command {
     case "radio uptime":  keyValues = "uptime=\(adjReply)".keyValuesArray()
     case "version":       keyValues = adjReply.keyValuesArray(delimiter: "#")
     case "ant list":      keyValues = "ant_list=\(adjReply)".keyValuesArray()
     case "mic list":      keyValues = "mic_list=\(adjReply)".keyValuesArray()
     case "info":          keyValues = adjReply.keyValuesArray(delimiter: ",")
     default: return
     }
     
     let properties = keyValues

    // NOTE: ObjectModel is @MainActor therefore it's methods and properties must be accessed asynchronously
    Task { await ObjectModel.shared.radio?.parse(properties) }
  }

  private func ipReplyHandler(_ command: String, _ seqNumber: Int, _ responseValue: String, _ reply: String) {
    // YES, resume it
    _awaitClientIpValidation?.resume(returning: reply)
  }

  private func wanValidationReplyHandler(_ command: String, _ seqNumber: Int, _ responseValue: String, _ reply: String) {
    // YES, resume it
    _awaitWanValidation?.resume(returning: reply)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Tcp parse methods

  /// Parse a Message.
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  private func parseMessage(_ msg: Substring) {
    // separate it into its components
    let components = msg.components(separatedBy: "|")
    
    // ignore incorrectly formatted messages
    if components.count < 2 {
      apiLog.warning("ApiModel: incomplete message = c\(msg)")
      return
    }
    
    // log it
    logFlexError(errorCode: components[0], msgText:  components[1])
    
    // FIXME: Take action on some/all errors?
  }

  /// Parse a Status
  /// - Parameters:
  ///   - commandSuffix:      a Command Suffix
  private func parseStatus(_ commandSuffix: Substring) {
    
    // separate it into its components ( [0] = <apiHandle>, [1] = <remainder> )
    let components = commandSuffix.components(separatedBy: "|")
    
    // ignore incorrectly formatted status
    guard components.count > 1 else {
      apiLog.warning("ApiModel: incomplete status = c\(commandSuffix)")
      return
    }
    
    // find the space & get the msgType
    let spaceIndex = components[1].firstIndex(of: " ")!
    let statusType = String(components[1][..<spaceIndex])
    
    // everything past the msgType is in the remainder
    let messageIndex = components[1].index(after: spaceIndex)
    let statusMessage = String(components[1][messageIndex...])
    
    // is this status message the first for our handle?
    if _firstStatusMessageReceived == false && components[0].handle == connectionHandle {
      // YES, set the API state to finish the UDP initialization
      _firstStatusMessageReceived = true
      _awaitFirstStatusMessage!.resume()
    }

    // NOTE: ObjectModel is @MainActor therefore it's methods and properties must be accessed asynchronously
    Task { await ObjectModel.shared.parse(statusType, statusMessage, self.connectionHandle) }
  }
}


// FIXME: Remove when no longer needed


extension Thread {
  public var threadName: String {
    if isMainThread {
      return "main"
    } else if let threadName = Thread.current.name, !threadName.isEmpty {
      return threadName
    } else {
      return description
    }
  }
}
