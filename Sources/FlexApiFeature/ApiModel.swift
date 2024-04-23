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

@MainActor
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
    
    atu = Atu()
    cwx = Cwx()
    gps = Gps()
    interlock = Interlock()
    transmit = Transmit()
    wan = Wan()
    waveform = Waveform()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // Dynamic Models
  public var amplifiers = IdentifiedArrayOf<Amplifier>()
  public var bandSettings = IdentifiedArrayOf<BandSetting>()
  public var equalizers = IdentifiedArrayOf<Equalizer>()
  public var memories = IdentifiedArrayOf<Memory>()
  public var meters = IdentifiedArrayOf<Meter>()
  public var panadapters = IdentifiedArrayOf<Panadapter>()
  public var profiles = IdentifiedArrayOf<Profile>()
  public var slices = IdentifiedArrayOf<Slice>()
  public var tnfs = IdentifiedArrayOf<Tnf>()
  public var usbCables = IdentifiedArrayOf<UsbCable>()
  public var waterfalls = IdentifiedArrayOf<Waterfall>()
  public var xvtrs = IdentifiedArrayOf<Xvtr>()
  
  // Static Models
  public var atu: Atu!
  public var cwx: Cwx!
  public var gps: Gps!
  public var interlock: Interlock!
  public var transmit: Transmit!
  public var wan: Wan!
  public var waveform: Waveform!

  // Reply Handlers
  public var replyHandlers : [UInt: ReplyTuple] {
    get { ApiModel.replyQ.sync { _replyHandlers } }
    set { ApiModel.replyQ.sync(flags: .barrier) { _replyHandlers = newValue }}}
  
  public var activeSlice: Slice?
  public internal(set) var antList = [String]()
  public internal(set) var atuPresent = false
  public internal(set) var boundClientId: String?
  public internal(set) var callsign = ""
  public internal(set) var chassisSerial = ""
  public internal(set) var firstStatusMessageReceived: Bool = false
  public internal(set) var clientInitialized: Bool = false
  public internal(set) var connectionHandle: UInt32?
  public internal(set) var fpgaMbVersion = ""
  public internal(set) var gateway = ""
  public internal(set) var gpsPresent = false
  public internal(set) var ipAddress = ""
  public var knownRadios = IdentifiedArrayOf<KnownRadio>()
  public internal(set) var location = ""
  public internal(set) var lowBandwidthConnect = false
  public internal(set) var macAddress = ""
  public internal(set) var micList = [String]()
  public internal(set) var netmask = ""
  public internal(set) var nickname = ""
  public internal(set) var nthPingReceived = false
  public internal(set) var numberOfScus = 0
  public internal(set) var numberOfSlices = 0
  public internal(set) var numberOfTx = 0
  public internal(set) var picDecpuVersion = ""
  public internal(set) var psocMbPa100Version = ""
  public internal(set) var psocMbtrxVersion = ""
  public internal(set) var radio: Radio?
  public internal(set) var radioModel = ""
  public internal(set) var radioOptions = ""
  public internal(set) var region = ""
  public internal(set) var radioScreenSaver = ""
  public internal(set) var sliceList = [UInt32]()               // FIXME: may not belong here
  public internal(set) var smartSdrMB = ""
  public internal(set) var softwareVersion = ""
  public var testMode = true
  public internal(set) var uptime = 0

  public enum ObjectType: String {
    case amplifier
    case atu
    case bandSetting = "band"
    case client
    case cwx
//    case daxIqStream = "dax_iq"
//    case daxMicAudioStream = "dax_mic"
//    case daxRxAudioStream = "dax_rx"
//    case daxTxAudioStream = "dax_tx"
    case display
    case equalizer = "eq"
    case gps
    case interlock
    case memory
    case meter
    case panadapter = "pan"
    case profile
    case radio
//    case remoteRxAudioStream = "remote_audio_rx"
//    case remoteTxAudioStream = "remote_audio_tx"
    case slice
    case stream
    case tnf
    case transmit
    case usbCable = "usb_cable"
    case wan
    case waterfall
    case waveform
    case xvtr
  }
  
  public enum StreamType: String {
    case daxIqStream = "dax_iq"
    case daxMicAudioStream = "dax_mic"
    case daxRxAudioStream = "dax_rx"
    case daxTxAudioStream = "dax_tx"
    case panadapter = "pan"
    case remoteRxAudioStream = "remote_audio_rx"
    case remoteTxAudioStream = "remote_audio_tx"
    case waterfall
  }

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
  
  var _isGui = true
  
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
  public func connect(selection: String, isGui: Bool, disconnectHandle: UInt32?, programName: String, mtuValue: Int, lowBandwidthDax: Bool = false) async throws {
    _isGui = isGui
    
    nthPingReceived = false
    
    if let packet = ListenerModel.shared.activePacket, let station = ListenerModel.shared.activeStation {
      // Instantiate a Radio
      radio = Radio(packet)
      // connect to it
      guard radio != nil else { throw ApiError.instantiation }
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
      sendInitialCommands(isGui, programName, station, mtuValue, lowBandwidthDax)
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
    removeAllObjects()
    log("ApiModel: Disconnect, Objects removed", .debug, #function, #file, #line)
    
    smartSdrMB = ""
    psocMbtrxVersion = ""
    psocMbPa100Version = ""
    fpgaMbVersion = ""
    
    // clear Published lists
//    Task {
//      await MainActor.run {
        antList.removeAll()
        micList.removeAll()
//        //    rfGainList.removeAll()
//        //    sliceList.removeAll()
//      }
//    }
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

  private func sendInitialCommands(_ isGui: Bool, _ programName: String, _ stationName: String, _ mtuValue: Int, _ lowBandwidthDax: Bool) {
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
