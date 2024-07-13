//
//  ObjectModel.swift
//
//
//  Created by Douglas Adams on 10/22/23.
//

import ComposableArchitecture
import Foundation

import ListenerFeature
import SharedFeature
import VitaFeature

@MainActor
@Observable
final public class ObjectModel: TcpProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = ObjectModel()
    private init() {
//  public init() {
    _tcp = Tcp(delegate: self)
    _udp = Udp(delegate: StreamModel.shared)
    atu = Atu(self)
    cwx = Cwx(self)
    gps = Gps(self)
    interlock = Interlock(self)
    transmit = Transmit(self)
    wan = Wan(self)
    waveform = Waveform(self)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public internal(set) var activePacket: Packet?
  public internal(set) var activeSlice: Slice?
  public internal(set) var activeStation: String?
  public internal(set) var boundClientId: String?
  public internal(set) var clientInitialized = false
  public internal(set) var connectionHandle: UInt32?
  public internal(set) var hardwareVersion: String?
  public internal(set) var radio: Radio?
  public var testDelegate: TcpProcessor?
  
  // single objects
  public var atu: Atu!
  public var cwx: Cwx!
  public var gps: Gps!
  public var interlock: Interlock!
  public var remoteRxAudio: RemoteRxAudio?
  public var transmit: Transmit!
  public var wan: Wan!
  public var waveform: Waveform!
  
  // collection objects
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
  
  // single stream objects
  public var daxMicAudio: DaxMicAudio?
  public var daxTxAudio: DaxTxAudio?
  public var meterStream: MeterStream?
  public var remoteTxAudio: RemoteTxAudio?
  
  // collection stream objects
  public var daxIqs = IdentifiedArrayOf<DaxIq>()
  public var daxRxAudios = IdentifiedArrayOf<DaxRxAudio>()
  public var panadapterStreams = IdentifiedArrayOf<PanadapterStream>()
  public var waterfallStreams = IdentifiedArrayOf<WaterfallStream>()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum ObjectType: String {
    case amplifier
    case atu
    case bandSetting = "band"
    case client
    case cwx
    case display
    case equalizer = "eq"
    case gps
    case interlock
    case memory
    case meter
    case panadapter = "pan"
    case profile
    case radio
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
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _awaitFirstStatusMessage: CheckedContinuation<(), Never>?
  private var _awaitWanValidation: CheckedContinuation<String, Never>?
  private var _awaitClientIpValidation: CheckedContinuation<String, Never>?
  private var _firstStatusMessageReceived: Bool = false
  private var _guiClientId: String?
  private var _pinger: Pinger?
  private var _replyDictionary = ReplyDictionary()
  private var _tcp: Tcp!
  private var _udp: Udp!
  private var _wanHandle = ""
  
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
  public func connect(packet: Packet?, station: String?, isGui: Bool, disconnectHandle: UInt32?, programName: String, mtuValue: Int, lowBandwidthDax: Bool = false, lowBandwidthConnect: Bool = false, testDelegate: TcpProcessor? = nil) async throws {
    
    self.testDelegate = testDelegate
    
    if let packet, let station {
      activePacket = packet
      activeStation = station
      
      // Instantiate a Radio
      radio = Radio(packet, isGui, self)
      guard radio != nil else { throw ApiError.instantiation }
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
    
    activePacket = nil
    activeStation = nil
    removeAllObjects()
    
    Task { await _replyDictionary.removeAll() }
    apiLog.debug("ApiModel: Disconnect, Objects removed")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public TCP message processor
  
  public func tcpProcessor(_ msg: String, isInput: Bool) {
    
    // received messages sent to the Tester
    testDelegate?.tcpProcessor(msg, isInput: true)
    
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
  ///   - diagnostic:     use "D"iagnostic form
  ///   - replyTo:       a callback function (if any)
  public func sendTcpAwaitReply(_ cmd: String, diagnostic: Bool = false) async -> (command:String, reply:String) {
    let reply = await withCheckedContinuation { continuation in
      _sendTcpReplyContinuation = continuation
      sendTcp(cmd, diagnostic: diagnostic, replyTo: sendTcpReplyHandler)
    }
    return (cmd, reply)
  }
  private var _sendTcpReplyContinuation: CheckedContinuation<String, Never>?
  
  private func sendTcpReplyHandler(_ command: String, _ reply: String) {
    _sendTcpReplyContinuation?.resume(returning: reply)
  }
  
  /// Send a command to the Radio (hardware) via TCP
  /// - Parameters:
  ///   - command:        a Command String
  ///   - diagnostic:     use "D"iagnostic form
  ///   - replyTo:       a callback function (if any)
  public func sendTcp(_ cmd: String, diagnostic: Bool = false, replyTo callback: ReplyHandler? = nil) {
    Task {
      // assign sequenceNumber & register to be notified when reply received
      let sequenceNumber = await _replyDictionary.add(cmd, callback: callback)
      
      // assemble the command
      let command =  "C" + "\(diagnostic ? "D" : "")" + "\(sequenceNumber)|" + cmd
      
      // tell TCP to send it
      _tcp.send(command + "\n", sequenceNumber)
      
      // sent messages provided to the Tester (if Tester exists)
      testDelegate?.tcpProcessor(command, isInput: true)
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
  // MARK: - Public methods
  
  
  
  
  
  public func remoteRxAudioReplyHandler(_ command: String, _ reply: String) {
    if let streamId = reply.streamId {
      //      Task {
      remoteRxAudio?.start(streamId)
      //      }
    }
  }
  
  
  
  
  
  
  
  public func clientInitialized(_ state: Bool) {
    clientInitialized = state
  }
  
  public func parse(_ statusType: String, _ statusMessage: String, _ connectionHandle: UInt32?) {
    
    // Check for unknown Object Types
    guard let objectType = ObjectType(rawValue: statusType)  else {
      // log it and ignore the message
      apiLog.warning("ObjectModel: unknown status token = \(statusType)")
      return
    }
    
    switch objectType {
    case .amplifier:            amplifierStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .atu:                  atu.parse( Array(statusMessage.keyValuesArray() ))
    case .bandSetting:          bandSettingStatus(Array(statusMessage.keyValuesArray().dropFirst(1) ), !statusMessage.contains(kRemoved))
    case .client:               preProcessClient(statusMessage.keyValuesArray(), !statusMessage.contains(kDisconnected), connectionHandle)
    case .cwx:                  cwx.parse( Array(statusMessage.keyValuesArray().dropFirst(1) ))
    case .display:              preProcessDisplay(statusMessage)
    case .equalizer:            equalizerStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .gps:                  gps.parse( Array(statusMessage.keyValuesArray(delimiter: "#").dropFirst(1)) )
    case .interlock:            preProcessInterlock(statusMessage)
    case .memory:               memoryStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .meter:                meterStatus(statusMessage.keyValuesArray(delimiter: "#"), !statusMessage.contains(kRemoved))
    case .profile:              profileStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kNotInUse), statusMessage)
    case .radio:                radio!.parse(statusMessage.keyValuesArray())
    case .slice:                sliceStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kNotInUse))
    case .stream:               preProcessStream(statusMessage, connectionHandle)
    case .tnf:                  tnfStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .transmit:             preProcessTransmit(statusMessage)
    case .usbCable:             usbCableStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kRemoved))
    case .wan:                  wan.parse( Array(statusMessage.keyValuesArray().dropFirst(1)) )
    case .waveform:             waveform.parse( Array(statusMessage.keyValuesArray(delimiter: "=").dropFirst(1)) )
    case .xvtr:                 xvtrStatus(statusMessage.keyValuesArray(), !statusMessage.contains(kNotInUse))
      
    case .panadapter, .waterfall: break                                                   // handled by "display"
    }
  }
  
  // ----- Meter methods -----
  
  public func meterBy(shortName: Meter.ShortName, slice: Slice? = nil) -> Meter? {
    
    if slice == nil {
      for meter in meters where meter.name == shortName.rawValue {
        return meter
      }
    } else {
      for meter in meters where slice!.id == UInt32(meter.group) && meter.name == shortName.rawValue {
        return meter
      }
    }
    return nil
  }
  
  // ----- Slice methods -----
  
  /// Find a Slice by DAX Channel
  ///
  /// - Parameter channel:    Dax channel number
  /// - Returns:              a Slice (if any)
  ///
  public func findSlice(using channel: Int) -> Slice? {
    // find the Slices with the specified Channel (if any)
    let filteredSlices = slices.filter { $0.daxChannel == channel }
    guard filteredSlices.count >= 1 else { return nil }
    
    // return the first one
    return filteredSlices[0]
  }
  
  public func sliceMove(_ panadapter: Panadapter, _ clickFrequency: Int) {
    
    let slices = slices.filter{ $0.panadapterId == panadapter.id }
    if slices.count == 1 {
      let roundedFrequency = clickFrequency - (clickFrequency % slices[0].step)
      slices[0].set(.frequency, roundedFrequency.hzToMhz)
      
    } else {
      let nearestSlice = slices.min{ a, b in
        abs(clickFrequency - a.frequency) < abs(clickFrequency - b.frequency)
      }
      if let nearestSlice {
        let roundedFrequency = clickFrequency - (clickFrequency % nearestSlice.step)
        nearestSlice.set(.frequency, roundedFrequency.hzToMhz)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  /// Remove all Radio objects
  func removeAllObjects() {
    radio = nil
    removeAll(of: .amplifier)
    removeAll(of: .bandSetting)
    removeAll(of: .equalizer)
    removeAll(of: .memory)
    removeAll(of: .meter)
    removeAll(of: .panadapter)
    removeAll(of: .profile)
    removeAll(of: .slice)
    removeAll(of: .tnf)
    removeAll(of: .usbCable)
    removeAll(of: .waterfall)
    removeAll(of: .xvtr)
  }
  
  func removeAll(of type: ObjectType) {
    switch type {
    case .amplifier:            amplifiers.removeAll()
    case .bandSetting:          bandSettings.removeAll()
    case .equalizer:            equalizers.removeAll()
    case .memory:               memories.removeAll()
    case .meter:                meters.removeAll()
    case .panadapter:           panadapters.removeAll()
    case .profile:              profiles.removeAll()
    case .slice:                slices.removeAll()
    case .tnf:                  tnfs.removeAll()
    case .usbCable:             usbCables.removeAll()
    case .waterfall:            waterfalls.removeAll()
    case .xvtr:                 xvtrs.removeAll()
    default:            break
    }
    apiLog.debug("ObjectModel: removed all \(type.rawValue) objects")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Object Status methods
  
  /// Evaluate a Status messaage
  /// - Parameters:
  ///   - properties: properties in KeyValuesArray form
  ///   - inUse: bool indicating status
  private func amplifierStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if amplifiers[id: id] == nil { amplifiers.append( Amplifier(id, self) ) }
        // parse the properties
        amplifiers[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        amplifiers.remove(id: id)
        apiLog.debug("Amplifier \(id.hex): REMOVED")
      }
    }
  }
  
  private func bandSettingStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if bandSettings[id: id] == nil { bandSettings.append( BandSetting(id, self) ) }
        // parse the properties
        bandSettings[id: id]!.parse(Array(properties.dropFirst(1)) )
      } else {
        // NO, remove it
        bandSettings.remove(id: id)
        apiLog.debug("BandSetting \(id): REMOVED")
      }
    }
  }
  
  private func daxIqStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxIqs[id: id] == nil { daxIqs.append( DaxIq(id) ) }
      // parse the properties
      daxIqs[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }
  
  private func daxMicAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxMicAudio == nil { daxMicAudio = DaxMicAudio(id) }
      // parse the properties
      daxMicAudio?.parse( Array(properties.dropFirst(1)) )
    }
  }
  
  private func daxRxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxRxAudios[id: id] == nil { daxRxAudios.append( DaxRxAudio(id) ) }
      // parse the properties
      daxRxAudios[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }
  
  private func daxTxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxTxAudio == nil { daxTxAudio = DaxTxAudio(id) }
      // parse the properties
      daxTxAudio?.parse( Array(properties.dropFirst(1)) )
    }
  }
  
  private func equalizerStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    let id = properties[0].key
    if id == "tx" || id == "rx" { return } // legacy equalizer ids, ignore
    // is it in use?
    if inUse {
      // YES, add it if not already present
      if equalizers[id: id] == nil { equalizers.append( Equalizer(id, self) ) }
      // parse the properties
      equalizers[id: id]!.parse(Array(properties.dropFirst(1)) )
      
    } else {
      // NO, remove it
      equalizers.remove(id: id)
      apiLog.debug("Equalizer \(id): REMOVED")
    }
  }
  
  private func memoryStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if memories[id: id] == nil { memories.append( Memory(id, self) ) }
        // parse the properties
        memories[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        memories.remove(id: id)
        apiLog.debug("Memory \(id): REMOVED")
      }
    }
  }
  
  private func meterStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = UInt32(properties[0].key.components(separatedBy: ".")[0], radix: 10) {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if meters[id: id] == nil { meters.append( Meter(id) ) }
        // parse the properties
        meters[id: id]!.parse(properties )
        
      } else {
        // NO, remove it
        meters.remove(id: id)
        apiLog.debug("Meter \(id): REMOVED")
      }
    }
  }
  
  private func panadapterStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.streamId {
      // is it in use?
      if inUse {
        // parse the properties
        // YES, add it if not already present
        if panadapters[id: id] == nil {
          panadapters.append( Panadapter(id, self) )
        }
        panadapters[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        panadapters.remove(id: id)
        apiLog.debug("Panadapter \(id.hex): REMOVED")
      }
    }
  }
  
  private func profileStatus(_ properties: KeyValuesArray, _ inUse: Bool, _ statusMessage: String) {
    // get the id
    let id = properties[0].key
    // is it in use?
    if inUse {
      // YES, add it if not already present
      if profiles[id: id] == nil { profiles.append( Profile(id, self) ) }
      // parse the properties
      profiles[id: id]!.parse(statusMessage )
      
    } else {
      // NO, remove it
      profiles.remove(id: id)
      apiLog.debug("Profile \(id): REMOVED")
    }
  }
  
  private func remoteRxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteRxAudio == nil { remoteRxAudio = RemoteRxAudio(id, self) }
      // parse the properties
      remoteRxAudio?.parse( Array(properties.dropFirst(2)) )
    }
  }
  
  private func remoteTxAudioStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteTxAudio == nil { remoteTxAudio = RemoteTxAudio(id)  }
      // parse the properties
      remoteTxAudio?.parse( Array(properties.dropFirst(2)) )
    }
  }
  
  private func sliceStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.objectId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if slices[id: id] == nil { slices.append(Slice(id, self)) }
        // parse the properties
        slices[id: id]!.parse(Array(properties.dropFirst(1)) )
        //        if slices[id: id]!.active { activeSlice = slices[id: id] }
        
      } else {
        // NO, remove it
        slices.remove(id: id)
        apiLog.debug("Slice \(id) REMOVED")
      }
    }
  }
  
  private func tnfStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = UInt32(properties[0].key, radix: 10) {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if tnfs[id: id] == nil { tnfs.append( Tnf(id, self) ) }
        // parse the properties
        tnfs[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        tnfs.remove(id: id)
        apiLog.debug("Tnf \(id): REMOVED")
      }
    }
  }
  
  private func usbCableStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    let id = properties[0].key
    // is it in use?
    if inUse {
      // YES, add it if not already present
      if usbCables[id: id] == nil { usbCables.append( UsbCable(id, self) ) }
      // parse the properties
      usbCables[id: id]!.parse(Array(properties.dropFirst(1)) )
      
    } else {
      // NO, remove it
      usbCables.remove(id: id)
      apiLog.debug("USBCable \(id): REMOVED")
    }
  }
  
  private func waterfallStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[0].key.streamId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if waterfalls[id: id] == nil {
          waterfalls.append( Waterfall(id, self) )
        }
        // parse the properties
        waterfalls[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        waterfalls.remove(id: id)
        apiLog.debug("Waterfall \(id.hex): REMOVED")
      }
    }
  }
  
  private func xvtrStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = properties[1].key.streamId {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if xvtrs[id: id] == nil { xvtrs.append( Xvtr(id, self) ) }
        // parse the properties
        xvtrs[id: id]!.parse(Array(properties.dropFirst(1)) )
        
      } else {
        // NO, remove it
        xvtrs.remove(id: id)
        apiLog.debug("Xvtr \(id): REMOVED")
      }
    }
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
  // MARK: - Private Pre-Process methods
  
  private func preProcessClient(_ properties: KeyValuesArray, _ inUse: Bool = true, _ connectionHandle: UInt32?) {
    // is there a valid handle"
    if let handle = properties[0].key.handle {
      switch properties[1].key {
        
      case kConnected:       parseConnection(properties: properties, handle: handle, connectionHandle: connectionHandle)
      case kDisconnected:    parseDisconnection(properties: properties, handle: handle, connectionHandle: connectionHandle)
      default:                      break
      }
    }
  }
  
  private func preProcessDisplay(_ statusMessage: String) {
    let properties = statusMessage.keyValuesArray()
    // Waterfall or Panadapter?
    switch properties[0].key {
    case ObjectType.panadapter.rawValue:  panadapterStatus(Array(statusMessage.keyValuesArray().dropFirst()), !statusMessage.contains(kRemoved) )
    case ObjectType.waterfall.rawValue:   waterfallStatus(Array(statusMessage.keyValuesArray().dropFirst()), !statusMessage.contains(kRemoved) )
    default: break
    }
  }
  
  private func preProcessInterlock(_ statusMessage: String) {
    let properties = statusMessage.keyValuesArray()
    // Band Setting or Interlock?
    switch properties[0].key {
    case ObjectType.bandSetting.rawValue:   bandSettingStatus(Array(statusMessage.keyValuesArray().dropFirst()), !statusMessage.contains(kRemoved) )
    default:                                interlock.parse(properties) ; interlockStateChange(interlock.state)
    }
  }
  
  public func preProcessStream(_ statusMessage: String, _ connectionHandle: UInt32?) {
    let properties = statusMessage.keyValuesArray()
    
    // is the 1st KeyValue a StreamId?
    if let id = properties[0].key.streamId {
      
      // is it a removal?
      if statusMessage.contains(kRemoved) {
        // YES
        removeStream(having: id)
        
      } else {
        // NO is it for me?
        if isForThisClient(properties, connectionHandle) {
          // YES
          guard properties.count > 1 else {
            apiLog.warning("StreamModel: invalid Stream message: \(statusMessage)")
            return
          }
          guard let token = StreamType(rawValue: properties[1].value) else {
            // log it and ignore the Key
            apiLog.warning("StreamModel: unknown Stream type: \(properties[1].value)")
            return
          }
          switch token {
            
          case .daxIqStream:          daxIqStatus(properties)
          case .daxMicAudioStream:    daxMicAudioStatus(properties)
          case .daxRxAudioStream:     daxRxAudioStatus(properties)
          case .daxTxAudioStream:     daxTxAudioStatus(properties)
          case .remoteRxAudioStream:  remoteRxAudioStatus(properties)
          case .remoteTxAudioStream:  remoteTxAudioStatus(properties)
            
          case .panadapter, .waterfall: break     // should never be seen here
          }
        }
      }
    } else {
      apiLog.warning("StreamModel: invalid Stream message: \(statusMessage)")
    }
  }
  
  private func preProcessTransmit(_ statusMessage: String) {
    let properties = statusMessage.keyValuesArray()
    // Band Setting or Transmit?
    switch properties[0].key {
    case ObjectType.bandSetting.rawValue:   bandSettingStatus(Array(statusMessage.keyValuesArray().dropFirst(1) ), !statusMessage.contains(kRemoved))
    default:                                transmit.parse( Array(properties.dropFirst() ))
    }
  }
  
  /// Change the MOX property when an Interlock state change occurs
  /// - Parameter state:            a new Interloack state
  private func interlockStateChange(_ state: String) {
    let currentMox = radio?.mox
    
    // if PTT_REQUESTED or TRANSMITTING
    if state == Interlock.States.pttRequested.rawValue || state == Interlock.States.transmitting.rawValue {
      // and mox not on, turn it on
      if currentMox == false { radio?.mox = true }
      
      // if READY or UNKEY_REQUESTED
    } else if state == Interlock.States.ready.rawValue || state == Interlock.States.unKeyRequested.rawValue {
      // and mox is on, turn it off
      if currentMox == true { radio?.mox = false  }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private parse methods
  
  /// Parse a client connect status message
  /// - Parameters:
  ///   - properties: message properties as a KeyValuesArray
  ///   - handle: the radio's connection handle
  private func parseConnection(properties: KeyValuesArray, handle: UInt32, connectionHandle: UInt32?) {
    var clientId = ""
    var program = ""
    var station = ""
    var isLocalPtt = false
    
    enum Property: String {
      case clientId = "client_id"
      case localPttEnabled = "local_ptt"
      case program
      case station
    }
    
    // if handle is mine, this client is fully initialized
    clientInitialized = ( handle == connectionHandle )
    
    // parse remaining properties
    for property in properties.dropFirst(2) {
      
      // check for unknown properties
      guard let token = Property(rawValue: property.key) else {
        // log it and ignore this Key
        apiLog.warning("ObjectModel: unknown client property, \(property.key)=\(property.value)")
        continue
      }
      // Known properties, in alphabetical order
      switch token {
        
      case .clientId:         clientId = property.value
      case .localPttEnabled:  isLocalPtt = property.value.bValue
      case .program:          program = property.value.trimmingCharacters(in: .whitespaces)
      case .station:          station = property.value.replacingOccurrences(of: "\u{007f}", with: "").trimmingCharacters(in: .whitespaces)
      }
    }
    
    if activePacket != nil {
      // is this GuiClient already in GuiClients?
      if activePacket!.guiClients[id: handle] != nil {
        
        // update the packet's GuiClients collection
        activePacket!.guiClients[id: handle]!.clientId = clientId
        activePacket!.guiClients[id: handle]!.program = program
        activePacket!.guiClients[id: handle]!.station = station
        activePacket!.guiClients[id: handle]!.isLocalPtt = isLocalPtt
        
        //        activePacket!.guiClients[id: handle] = guiClient
        
        // log the addition
        apiLog.info("ObjectModel: guiClient UPDATED, \(handle.hex), \(station), \(program), \(clientId)")
        
        if radio!.isGui == false && station == activeStation {
          boundClientId = clientId
          sendTcp("client bind client_id=\(clientId)")
          apiLog.debug("ObjectModel: NonGui bound to \(station), \(program)")
        }
        //        }
      } else {
        // NO
        let guiClient = GuiClient(handle: handle,
                                  station: station,
                                  program: program,
                                  clientId: clientId,
                                  isLocalPtt: isLocalPtt,
                                  isThisClient: handle == connectionHandle)
        activePacket!.guiClients[id: handle] = guiClient
        
        // log the addition
        apiLog.info("ObjectModel: guiClient ADDED, \(handle.hex), \(station), \(program), \(clientId)")
        
        if !clientId.isEmpty && !program.isEmpty && !station.isEmpty {
          // the fields are populated
          
          activePacket!.guiClients[id: handle] = guiClient
          
          if radio!.isGui == false && station == activeStation {
            boundClientId = clientId
            sendTcp("client bind client_id=\(clientId)")
            apiLog.debug("ObjectModel: NonGui bound to \(station), \(program)")
          }
        }
      }
    }
  }
  
  /// Parse a client disconnect status message
  /// - Parameters:
  ///   - properties: message properties as a KeyValuesArray
  ///   - handle: the radio's connection handle
  private func parseDisconnection(properties: KeyValuesArray, handle: UInt32, connectionHandle: UInt32?) {
    var reason = ""
    
    enum Property: String {
      case duplicateClientId        = "duplicate_client_id"
      case forced
      case wanValidationFailed      = "wan_validation_failed"
    }
    
    // is it me?
    if handle == connectionHandle {
      // YES, parse remaining properties
      for property in properties.dropFirst(2) {
        // check for unknown property
        guard let token = Property(rawValue: property.key) else {
          // log it and ignore this Key
          apiLog.warning("ObjectModel: unknown client disconnection property, \(property.key)=\(property.value)")
          continue
        }
        // Known properties, in alphabetical order
        switch token {
          
        case .duplicateClientId:    if property.value.bValue { reason = "Duplicate ClientId" }
        case .forced:               if property.value.bValue { reason = "Forced" }
        case .wanValidationFailed:  if property.value.bValue { reason = "Wan validation failed" }
        }
      }
      apiLog.warning("ObjectModel: client disconnection, reason = \(reason)")
      
      clientInitialized = false
      
    } else {
      // NO, not me
      activePacket?.guiClients[id: handle] = nil
    }
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
  private func defaultReplyProcessor(_ reply: Substring) {
    
    // separate it into its components
    let components = reply.components(separatedBy: "|")
    // ignore incorrectly formatted replies
    if components.count < 2 {
      apiLog.warning("ApiModel: incomplete reply, r\(reply)")
      return
    }
    
    // get the sequence number, reply and any additional data
    let seqNum = components[0].sequenceNumber
    let replyValue = components[1]
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
        if replyValue != kNoError && !command.hasPrefix("client program ") {
          apiLog.error("ApiModel: replyValue >\(replyValue)<, to c\(seqNum), \(command), \(flexErrorString(errorCode: replyValue)), \(suffix)")
        }
        // did the replyTuple include a callback?
        if let callback = replyTuple.callback{
          // YES, call the sender's Handler
          callback(command, String(reply))
        }
      } else {
        apiLog.error("ApiModel: \(reply) replyValue >\(replyValue)<, unknown sequence number c\(seqNum), \(flexErrorString(errorCode: replyValue)), \(suffix)")
      }
    }
  }
  
  private func initialCommandsReplyHandler(_ command: String, _ reply: String) {
    var keyValues: KeyValuesArray
    
    // separate it into its components
    let components = reply.components(separatedBy: "|")
    // ignore incorrectly formatted replies
    if components.count < 2 {
      apiLog.warning("ApiModel: incomplete reply, r\(reply)")
      return
    }
    
    // get the sequence number, reply and any additional data
    //    let seqNum = components[0].sequenceNumber
    let replyValue = components[1]
    //    let suffix = components.count < 3 ? "" : components[2]
    
    let adjReplyValue = replyValue.replacingOccurrences(of: "\"", with: "")
    
    // process replies to the internal "sendCommands"?
    switch command {
    case "radio uptime":  keyValues = "uptime=\(adjReplyValue)".keyValuesArray()
    case "version":       keyValues = adjReplyValue.keyValuesArray(delimiter: "#")
    case "ant list":      keyValues = "ant_list=\(adjReplyValue)".keyValuesArray()
    case "mic list":      keyValues = "mic_list=\(adjReplyValue)".keyValuesArray()
    case "info":          keyValues = adjReplyValue.keyValuesArray(delimiter: ",")
    default: return
    }
    
    //    let properties = keyValues
    
    //    radio?.parse(properties)
    radio?.parse(keyValues)
  }
  
  private func ipReplyHandler(_ command: String, _ reply: String) {
    // YES, resume it
    _awaitClientIpValidation?.resume(returning: reply)
  }
  
  private func wanValidationReplyHandler(_ command: String, _ reply: String) {
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
    
    parse(statusType, statusMessage, self.connectionHandle)
  }
  
  
  // FIXME: Remove when no longer needed
  
  
  //extension Thread {
  //  public var threadName: String {
  //    if isMainThread {
  //      return "main"
  //    } else if let threadName = Thread.current.name, !threadName.isEmpty {
  //      return threadName
  //    } else {
  //      return description
  //    }
  //  }
  //}
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Removal methods
  
  private func removeStream(having id: UInt32) {
    if daxIqs[id: id] != nil {
      daxIqs.remove(id: id)
      apiLog.debug("ObjectModel: DaxIq \(id.hex): REMOVED")
    }
    else if daxMicAudio?.id == id {
      daxMicAudio = nil
      apiLog.debug("ObjectModel: DaxMicAudio \(id.hex): REMOVED")
    }
    else if daxRxAudios[id: id] != nil {
      daxRxAudios.remove(id: id)
      apiLog.debug("ObjectModel: DaxRxAudio \(id.hex): REMOVED")
      
    } else if daxTxAudio?.id == id {
      daxTxAudio = nil
      apiLog.debug("ObjectModel: DaxTxAudio \(id.hex): REMOVED")
    }
    else if remoteRxAudio?.id == id {
      remoteRxAudio = nil
      apiLog.debug("ObjectModel: RemoteRxAudio \(id.hex): REMOVED")
    }
    else if remoteTxAudio?.id == id {
      remoteTxAudio = nil
      apiLog.debug("ObjectModel: RemoteTxAudio \(id.hex): REMOVED")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Helper methods
  
  /// Determine if status is for this client
  /// - Parameters:
  ///   - properties:     a KeyValuesArray
  ///   - clientHandle:   the handle of ???
  /// - Returns:          true if a mtch
  private func isForThisClient(_ properties: KeyValuesArray, _ connectionHandle: UInt32?) -> Bool {
    var clientHandle : UInt32 = 0
    
    guard testDelegate != nil else { return true }
    
    if let connectionHandle {
      // find the handle property
      for property in properties.dropFirst(2) where property.key == "client_handle" {
        clientHandle = property.value.handle ?? 0
      }
      return clientHandle == connectionHandle
    }
    return false
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  /// Process the Vita struct containing Meter data
  /// - Parameters:
  ///   - vita:        a Vita struct
  public nonisolated func streamProcessor(_ vita: Vita) {
    let kDbDbmDbfsSwrDenom: Float = 128.0   // denominator for Db, Dbm, Dbfs, Swr
    let kDegDenom: Float = 64.0             // denominator for Degc, Degf
    
    var meterIds = [UInt32]()
    
    //    if isStreaming == false {
    //      isStreaming = true
    //      streamId = vita.streamId
    //      // log the start of the stream
    //      log("Meter \(vita.streamId.hex) stream: STARTED", .info, #function, #file, #line)
    //    }
    
    // NOTE:  there is a bug in the Radio (as of v2.2.8) that sends
    //        multiple copies of meters, this code ignores the duplicates
    
    vita.payloadData.withUnsafeBytes { payloadPtr in
      // four bytes per Meter
      let numberOfMeters = Int(vita.payloadSize / 4)
      
      // pointer to the first Meter number / Meter value pair
      let ptr16 = payloadPtr.bindMemory(to: UInt16.self)
      
      // for each meter in the Meters packet
      for i in 0..<numberOfMeters {
        // get the Meter id and the Meter value
        let id: UInt32 = UInt32(CFSwapInt16BigToHost(ptr16[2 * i]))
        let value: UInt16 = CFSwapInt16BigToHost(ptr16[(2 * i) + 1])
        
        // is this a duplicate?
        if !meterIds.contains(id) {
          // NO, add it to the list
          meterIds.append(id)
          
          // find the meter (if present) & update it
          // NOTE: ObjectModel is @MainActor therefore it's methods and properties must be accessed asynchronously
          Task {
            if let meter = await meters[id: id] {
              //          meter.streamHandler( value)
              let newValue = Int16(bitPattern: value)
              let previousValue = await meter.value
              
              // check for unknown Units
              guard let token = await MeterUnits(rawValue: meter.units) else {
                //      // log it and ignore it
                //      log("Meter \(desc) \(description) \(group) \(name) \(source): unknown units - \(units))", .warning, #function, #file, #line)
                return
              }
              var adjNewValue: Float = 0.0
              switch token {
                
              case .db, .dbm, .dbfs, .swr:        adjNewValue = Float(exactly: newValue)! / kDbDbmDbfsSwrDenom
              case .volts, .amps:                 adjNewValue = Float(exactly: newValue)! / 256.0
              case .degc, .degf:                  adjNewValue = Float(exactly: newValue)! / kDegDenom
              case .rpm, .watts, .percent, .none: adjNewValue = Float(exactly: newValue)!
              }
              // did it change?
              if adjNewValue != previousValue {
                let value = adjNewValue
                await meter.setValue(value)
              }
            }
          }
        }
      }
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
