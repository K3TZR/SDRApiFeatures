//
//  Api.swift
//  
//
//  Created by Douglas Adams on 4/11/23.
//

import ComposableArchitecture
import Foundation

import ListenerFeature
import SharedFeature
import TcpFeature
import UdpFeature
import VitaFeature
import XCGLogFeature

public typealias Hz = Int
public typealias MHz = Double

public typealias ReplyHandler = (_ command: String, _ seqNumber: UInt, _ responseValue: String, _ reply: String) -> Void
public typealias ReplyTuple = (replyTo: ReplyHandler?, command: String)

//@MainActor
@Observable
public final class ApiModel {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = ApiModel()
  private init() {

    subscribeToMessages()
    
    if UserDefaults.standard.string(forKey: "guiClientId") == nil {
      UserDefaults.standard.set(UUID().uuidString, forKey: "guiClientId")
    }
  }

  // Reply Handlers
  public var replyHandlers : [UInt: ReplyTuple] {
    get { ApiModel.replyQ.sync { _replyHandlers } }
    set { ApiModel.replyQ.sync(flags: .barrier) { _replyHandlers = newValue }}}
    
  public var activeSlice: Slice?
  public internal(set) var firstStatusMessageReceived: Bool = false
  public internal(set) var clientInitialized: Bool = false
  public internal(set) var connectionHandle: UInt32?
  public var knownRadios = IdentifiedArrayOf<KnownRadio>()
//  public internal(set) var lowBandwidthConnect = false
  public internal(set) var nthPingReceived = false
  public var testMode = true
  public internal(set) var uptime = 0

  public internal(set) var smartSdrMB = ""
  public internal(set) var fpgaMbVersion = ""
  public internal(set) var picDecpuVersion = ""
  public internal(set) var psocMbPa100Version = ""
  public internal(set) var psocMbtrxVersion = ""

  public internal(set) var antList = [String]()
  public internal(set) var sliceList = [UInt32]()               // FIXME: may not belong here
  public internal(set) var micList = [String]()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _guiClientId: String?
  private var _pinger: Pinger?
  private var _replyHandlers = [UInt: ReplyTuple]()
  private var _wanHandle = ""

  // ----------------------------------------------------------------------------
  // MARK: - Static properties

  static let replyQ = DispatchQueue(label: "replyQ", attributes: [.concurrent])

  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _awaitFirstStatusMessage: CheckedContinuation<(), Never>?
  var _awaitWanValidation: CheckedContinuation<String, Never>?
  var _awaitClientIpValidation: CheckedContinuation<String, Never>?
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Connection methods

  /// Connect to a Radio
  /// - Parameters:
  ///   - selection: selection from the Radio Picker
  ///   - isGui: true = GUI
  ///   - disconnectHandle: handle to another connection to be disconnected (if any)
  ///   - programName: program name
  ///   - mtuValue: max transort unit
  ///   - lowBandwidthDax: true = use low bw
  public func connect(selection: String, isGui: Bool, disconnectHandle: UInt32?, programName: String, mtuValue: Int, lowBandwidthDax: Bool = false, lowBandwidthConnect: Bool = false) async throws {
//    self.isGui = isGui
    
    nthPingReceived = false
    
    if let packet = ListenerModel.shared.activePacket, let station = ListenerModel.shared.activeStation {
      // Instantiate a Radio
      try await MainActor.run{
        ObjectModel.shared.radio = Radio(packet, isGui)
        guard ObjectModel.shared.radio != nil else { throw ApiError.instantiation }
      }
      log("ApiModel: Radio instantiated for \(packet.nickname), \(packet.source)", .debug, #function, #file, #line)
      
      guard connect(packet) else { throw ApiError.connection }
      log("ApiModel: Tcp connection established ", .debug, #function, #file, #line)
      
      if disconnectHandle != nil {
        // pending disconnect
        sendCommand("client disconnect \(disconnectHandle!.hex)")
      }
      
      // wait for the first Status message with my handle
      try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [self] in
        await awaitFirstStatusMessage()
      }
      log("ApiModel: First status message received", .debug, #function, #file, #line)
      
      // is this a Wan connection?
      if packet.source == .smartlink {
        // YES, send Wan Connect message & wait for the reply
        _wanHandle = try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [serial = packet.serial, negotiatedHolePunchPort = packet.negotiatedHolePunchPort] in
          try await ListenerModel.shared.smartlinkConnect(for: serial, holePunchPort: negotiatedHolePunchPort)
        }
        
        log("ApiModel: wanHandle received", .debug, #function, #file, #line)
        
        // send Wan Validate & wait for the reply
        log("Api: Wan validate sent for handle=\(_wanHandle)", .debug, #function, #file, #line)
        sendCommand("wan validate handle=\(_wanHandle)", replyTo: wanValidationReply)
        let reply = try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [self] in
          //          _ = try await sendCommandAwaitReply("wan validate handle=\(_wanHandle)")
          //          await sendCommand("wan validate handle=\(_wanHandle), callback: awaitWanValidation")
          
          await wanValidation()
        }
        log("ApiModel: Wan validation = \(reply)", .debug, #function, #file, #line)
      }
      // bind UDP
      let ports = Udp.shared.bind(packet.source == .smartlink,
                                  packet.publicIp,
                                  packet.requiresHolePunch,
                                  packet.negotiatedHolePunchPort,
                                  packet.publicUdpPort)
      
      guard ports != nil else { Tcp.shared.disconnect() ; throw ApiError.udpBind }
      log("ApiModel: UDP bound, receive port = \(ports!.0), send port = \(ports!.1)", .debug, #function, #file, #line)
      
      // is this a Wan connection?
      if packet.source == .smartlink {
        // send Wan Register (no reply)
        sendUdp(string: "client udp_register handle=" + connectionHandle!.hex )
        log("ApiModel: UDP registration sent", .debug, #function, #file, #line)
        
        // send Client Ip & wait for the reply
        sendCommand("client ip", replyTo: clientIpReply)
        let reply = try await withTimeout(seconds: 5.0, errorToThrow: ApiError.statusTimeout) { [self] in
          await clientIpValidation()
        }
        log("ApiModel: Client ip = \(reply)", .debug, #function, #file, #line)
      }
      
      // send the initial commands
      sendInitialCommands(isGui, programName, station, mtuValue, lowBandwidthDax, lowBandwidthConnect)
      log("ApiModel: initial commands sent", .info, #function, #file, #line)
      
      startPinging()
      log("ApiModel: pinging \(packet.publicIp)", .info, #function, #file, #line)
      
      // set the UDP port for a Local connection
      if packet.source == .local {
        sendCommand("client udpport " + "\(Udp.shared.sendPort)")
        log("ApiModel: Client Udp port set to \(Udp.shared.sendPort)", .info, #function, #file, #line)
      }
    }
  }
  
  /// Disconnect the current Radio and remove all its objects / references
  /// - Parameter reason: an optional reason
  public func disconnect(_ reason: String? = nil) {
    log("ApiModel: Disconnect, \((reason == nil ? "User initiated" : reason!))", reason == nil ? .debug : .warning, #function, #file, #line)
    
    clientInitialized = false
    firstStatusMessageReceived = false
    nthPingReceived = false
    
    // stop pinging (if active)
    stopPinging()
    log("ApiModel: Pinging STOPPED", .debug, #function, #file, #line)
    
    connectionHandle = nil
    
    // stop udp
    Udp.shared.unbind()
    log("ApiModel: Disconnect, UDP unbound", .debug, #function, #file, #line)
    
    //    streamModel.unSubscribeToStreams()
    
    Tcp.shared.disconnect()
    
    ListenerModel.shared.activePacket = nil
    ListenerModel.shared.activeStation = nil
    
    // remove all of radio's objects
    Task { await MainActor.run { ObjectModel.shared.removeAllObjects() } }
    log("ApiModel: Disconnect, Objects removed", .debug, #function, #file, #line)
    
    smartSdrMB = ""
    psocMbtrxVersion = ""
    psocMbPa100Version = ""
    fpgaMbVersion = ""
    antList.removeAll()
    micList.removeAll()
  }

  func tcpInbound(_ message: String) {
    // pass to the Tester (if any)
    //    _testerDelegate?.tcpInbound(message)
    
    // switch on the first character of the text
    switch message.prefix(1) {
      
    case "H", "h":  connectionHandle = String(message.dropFirst()).handle ; log("Api: connectionHandle = \(connectionHandle?.hex ?? "missing")", .debug, #function, #file, #line)
    case "M", "m":  parseMessage( message.dropFirst() )
    case "R", "r":  parseReply( message )
    case "S", "s":  parseStatus( message.dropFirst() )
    case "V", "v":  break /*Task { await MainActor.run { radio?.hardwareVersion = String(message.dropFirst()) }}*/
    default:        log("ApiModel: unexpected message = \(message)", .warning, #function, #file, #line)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods

  private func awaitFirstStatusMessage() async {
    return await withCheckedContinuation{ continuation in
      _awaitFirstStatusMessage = continuation
      log("ApiModel: waiting for first status message", .debug, #function, #file, #line)
    }
  }
  
  private func clientIpValidation() async -> (String) {
    return await withCheckedContinuation{ continuation in
      _awaitClientIpValidation = continuation
      log("Api: Client ip request sent", .debug, #function, #file, #line)
    }
  }
  
  private func clientIpReply(_ command: String, _ seqNumber: UInt, _ responseValue: String, _ reply: String) {
    // YES, resume it
    _awaitClientIpValidation?.resume(returning: reply)
  }

  /// Connect to a Radio
  /// - Parameter params:     a struct of parameters
  /// - Returns:              success / failure
  private func connect(_ packet: Packet) -> Bool {
    return Tcp.shared.connect(packet.source == .smartlink,
                              packet.requiresHolePunch,
                              packet.negotiatedHolePunchPort,
                              packet.publicTlsPort,
                              packet.port,
                              packet.publicIp,
                              packet.localInterfaceIP)
  }

  /// Parse the Reply to an Info command
  /// - Parameters:
  ///   - suffix:          a reply string
  private func parseInfoReply(_ suffix: String) {
    
    let properties = suffix.replacingOccurrences(of: "\"", with: "").keyValuesArray(delimiter: ",")
    Task {
      await MainActor.run {
        ObjectModel.shared.radio?.parse(properties)
      }
    }
//
//    
//    enum Property: String {
//        case atuPresent               = "atu_present"
//        case callsign
//        case chassisSerial            = "chassis_serial"
//        case gateway
//        case gps
//        case ipAddress                = "ip"
//        case location
//        case macAddress               = "mac"
//        case model
//        case netmask
//        case name
//        case numberOfScus             = "num_scu"
//        case numberOfSlices           = "num_slice"
//        case numberOfTx               = "num_tx"
//        case options
//        case region
//        case screensaver
//        case softwareVersion          = "software_ver"
//    }
//      // process each key/value pair, <key=value>
//    for property in suffix.replacingOccurrences(of: "\"", with: "").keyValuesArray(delimiter: ",") {
//          // check for unknown Keys
//          guard let token = Property(rawValue: property.key) else {
//              // log it and ignore the Key
//              log("ApiModel: unknown info token, \(property.key) = \(property.value)", .warning, #function, #file, #line)
//              continue
//          }
//          // Known keys, in alphabetical order
//          switch token {
//
//          case .atuPresent:       atuPresent = property.value.bValue
//          case .callsign:         callsign = property.value
//          case .chassisSerial:    chassisSerial = property.value
//          case .gateway:          gateway = property.value
//          case .gps:              gpsPresent = (property.value != "Not Present")
//          case .ipAddress:        ipAddress = property.value
//          case .location:         location = property.value
//          case .macAddress:       macAddress = property.value
//          case .model:            radioModel = property.value
//          case .netmask:          netmask = property.value
//          case .name:             nickname = property.value
//          case .numberOfScus:     numberOfScus = property.value.iValue
//          case .numberOfSlices:   numberOfSlices = property.value.iValue
//          case .numberOfTx:       numberOfTx = property.value.iValue
//          case .options:          radioOptions = property.value
//          case .region:           region = property.value
//          case .screensaver:      radioScreenSaver = property.value
//          case .softwareVersion:  softwareVersion = property.value
//          }
//      }
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

      case "slice list":    sliceList = suffix.valuesArray().compactMap { UInt32($0, radix: 10) }
      case "ant list":      antList = suffix.valuesArray( delimiter: "," )
      case "info":          parseInfoReply(suffix)
      case "mic list":      micList = suffix.valuesArray(  delimiter: "," )
      case "radio uptime":  uptime = Int(suffix) ?? 0
      case "version":       parseVersionReply(suffix)

      default: break
      }
      
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
    
    // is this status message the first for our handle?
    if firstStatusMessageReceived == false && components[0].handle == connectionHandle {
      // YES, set the API state to finish the UDP initialization
      firstStatusMessageReceived = true
      _awaitFirstStatusMessage!.resume()
    }
    Task {
      await MainActor.run {
        ObjectModel.shared.parse(statusType, statusMessage, connectionHandle, testMode)
      }
    }
  }
  
  /// Parse the Reply to a Version command, reply format: <key=value>#<key=value>#...<key=value>
  /// - Parameters:
  ///   - suffix:          a reply string
  private func parseVersionReply(_ suffix: String) {
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
        log("ObjectModel: unknown version property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
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

  private func sendInitialCommands(_ isGui: Bool, _ programName: String, _ stationName: String, _ mtuValue: Int, _ lowBandwidthDax: Bool, _ lowBandwidthConnect: Bool) {
    let guiClientId = UserDefaults.standard.string(forKey: "guiClientId")
    
    if isGui && guiClientId == nil {
      sendCommand("client gui")
    }
    if isGui && guiClientId != nil {
      sendCommand("client gui \(guiClientId!)")
    }
    sendCommand("client program " + programName)
    if isGui { sendCommand("client station " + stationName) }
    if lowBandwidthConnect { requestLowBandwidthConnect() }
    requestInfo()
    requestVersion()
    requestAntennaList()
    requestMicList()
    requestGlobalProfile()
    requestTxProfile()
    requestMicProfile()
    requestDisplayProfile()
    sendSubAll()
    requestMtuLimit(mtuValue)
    requestLowBandwidthDax(lowBandwidthDax)
    requestUptime()
  }

  private func sendSubAll(callback: ReplyHandler? = nil) {
    sendCommand("sub tx all")
    sendCommand("sub atu all")
    sendCommand("sub amplifier all")
    sendCommand("sub meter all")
    sendCommand("sub pan all")
    sendCommand("sub slice all")
    sendCommand("sub gps all")
    sendCommand("sub audio_stream all")
    sendCommand("sub cwx all")
    sendCommand("sub xvtr all")
    sendCommand("sub memories all")
    sendCommand("sub daxiq all")
    sendCommand("sub dax all")
    sendCommand("sub usb_cable all")
    sendCommand("sub tnf all")
    sendCommand("sub client all")
    //      send("sub spot all")    // TODO:
  }

  private func startPinging() {
    // tell the Radio to expect pings
    sendCommand("keepalive enable")
    // start pinging the Radio
    _pinger = Pinger(self)
  }

  private func stopPinging() {
    _pinger?.stopPinging()
    _pinger = nil
  }

  /// Process the AsyncStream of inbound TCP messages
  private func subscribeToMessages()  {
    Task(priority: .high) {
      log("ApiModel: TcpMessage subscription STARTED", .debug, #function, #file, #line)
      for await tcpMessage in Tcp.shared.inboundMessagesStream {
        tcpInbound(tcpMessage.text)
      }
      log("ApiModel: TcpMessage subscription STOPPED", .debug, #function, #file, #line)
    }
  }
  
  private func wanValidation() async -> (String) {
    return await withCheckedContinuation{ continuation in
      _awaitWanValidation = continuation
      log("Api: Wan validate sent for handle=\(_wanHandle)", .debug, #function, #file, #line)
    }
  }

  private func wanValidationReply(_ command: String, _ seqNumber: UInt, _ responseValue: String, _ reply: String) {
    // YES, resume it
    _awaitWanValidation?.resume(returning: reply)
  }
}
