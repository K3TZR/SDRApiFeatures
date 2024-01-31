//
//  Listener.swift
//  FlexApiFeature/Listener
//
//  Created by Douglas Adams on 11/26/22.
//

import ComposableArchitecture
import Foundation

import SharedFeature
import XCGLogFeature

public typealias IdToken = String
public typealias RefreshToken = String

//extension Listener: DependencyKey {
//  public static let liveValue = Listener(previousIdToken: nil)
//}
//
//extension DependencyValues {
//  public var listener: Listener {
//    get { self[Listener.self] }
//  }
//}

@Observable
final public class ListenerModel: Equatable {
  public static func == (lhs: ListenerModel, rhs: ListenerModel) -> Bool {
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Properties
  
  public var packets = IdentifiedArrayOf<Packet>()
  public var stations = IdentifiedArrayOf<Station>()
  public var activePacket: Packet?
  public var activeStation: String?

  public var smartlinkTestResult = SmartlinkTestResult()

  public var clientStream: AsyncStream<ClientEvent> {
    AsyncStream { continuation in _clientStream = { clientEvent in continuation.yield(clientEvent) }
      continuation.onTermination = { @Sendable _ in } }}
  
  public var statusStream: AsyncStream<WanStatus> {
    AsyncStream { continuation in _statusStream = { status in continuation.yield(status) }
      continuation.onTermination = { @Sendable _ in } }}
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _localListener: LocalListener?
  private var _smartlinkListener: SmartlinkListener?
  
  private var _clientStream: (ClientEvent) -> Void = { _ in }
  var _statusStream: (WanStatus) -> Void = { _ in }
  
  private let _formatter = DateFormatter()
  
  private enum UpdateStatus {
    case newPacket
    case timestampOnly
    case changedPacket
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = ListenerModel()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func setActive(_ isGui: Bool, _ selection: String, _ directMode: Bool = false) {
    if directMode {
      
      let serial = String(selection.prefix(19))
      let publicIp = String(selection.suffix(from: selection.index(selection.startIndex, offsetBy: 19)))
      
      if isGui {
        activePacket = Packet(nickname: "DIRECT", serial: serial, publicIp: publicIp, port: 4_992)
        activeStation = "SDRApi"
      } else {
        fatalError()
      }
      
    } else {
      if isGui {
        activePacket = packets[id: selection]!
        activeStation = "SDRApi"
      } else {
        activePacket  = stations[id: selection]!.packet
        activeStation = stations[id: selection]!.station
      }
    }
  }
  
  public func localMode(_ enable: Bool) {
    _localListener?.stop()
    _localListener = nil
    
    if enable {
      _localListener = LocalListener(self)
      _localListener!.start()
    } else {
      removePackets(condition: {$0.source == .local})
    }
  }
  
  public func smartlinkMode(_ user: String = "", _ loginRequired: Bool = false, _ previousIdToken: String?, _ refreshToken: String?) async -> Tokens {
    _smartlinkListener?.stop()
    _smartlinkListener = nil
    
    _smartlinkListener = SmartlinkListener(self)
    let tokens = await _smartlinkListener!.start(Tokens(previousIdToken, refreshToken))
    if tokens.idToken != nil {
      log("Smartlink Listener: STARTED", .debug, #function, #file, #line)
      return tokens
    } else {
      _smartlinkListener = nil
      return Tokens(nil, nil)
    }
  }
  
  public func smartlinkStart(_ user: String, _ pwd: String) async -> Tokens {
    _smartlinkListener = SmartlinkListener(self)
    let tokens = await _smartlinkListener!.start(user: user, pwd: pwd)
    if tokens.idToken != nil {
      log("Smartlink Listener: Login SUCCESS", .debug, #function, #file, #line)
      return tokens
    } else {
      log("Smartlink Listener: Login FAILURE", .debug, #function, #file, #line)
      _smartlinkListener = nil
      return Tokens(nil, nil)
    }
  }
  
  /// Send a Test message
  /// - Parameter serial:     radio serial number
  /// - Returns:              success / failure
  public func smartlinkTest(_ selection: String) {
    let serial = selection.prefix(19)
    log("Smartlink Listener: test initiated to serial number, \(serial)", .debug, #function, #file, #line)
    // send a command to SmartLink to test the connection for the specified Radio
    _smartlinkListener?.sendTlsCommand("application test_connection serial=\(serial)")
  }
  
  /// Initiate a smartlink connection to a radio
  /// - Parameters:
  ///   - serialNumber:       the serial number of the Radio
  ///   - holePunchPort:      the negotiated Hole Punch port number
  /// - Returns:              a WanHandle
  public func smartlinkConnect(for serial: String, holePunchPort: Int) async throws -> String {
    
    return try await withCheckedThrowingContinuation{ continuation in
      _smartlinkListener?.awaitWanHandle = continuation
      log("Smartlink Listener: Connect sent to serial \(serial)", .debug, #function, #file, #line)
      // send a command to SmartLink to request a connection to the specified Radio
      _smartlinkListener?.sendTlsCommand("application connect serial=\(serial) hole_punch_port=\(holePunchPort))")
    }
  }
  
  /// Disconnect a smartlink Radio
  /// - Parameter serialNumber:         the serial number of the Radio
  public func smartlinkDisconnect(for serial: String) {
    log("Smartlink Listener: Disconnect sent to serial \(serial)", .debug, #function, #file, #line)
    // send a command to SmartLink to request disconnection from the specified Radio
    _smartlinkListener?.sendTlsCommand("application disconnect_users serial=\(serial)")
  }
  
  /// Disconnect a single smartlink Client
  /// - Parameters:
  ///   - serialNumber:         the serial number of the Radio
  ///   - handle:               the handle of the Client
  public func smartlinkDisconnectClient(for serial: String, handle: UInt32) {
    log("Smartlink Listener: Disconnect sent to serial \(serial), handle \(handle.hex)", .debug, #function, #file, #line)
    // send a command to SmartLink to request disconnection from the specified Radio
    _smartlinkListener?.sendTlsCommand("application disconnect_users serial=\(serial) handle=\(handle.hex)")
  }
  
  public func isValidDefault(for guiDefault: String?, _ nonGuiDefault: String?, _ isGui: Bool) -> Bool {
    if isGui {
      guard guiDefault != nil else { return false }
      return packets[id: guiDefault!] != nil
      
    } else {
      guard nonGuiDefault != nil else { return false }
      return stations[id: nonGuiDefault!] != nil
    }
  }
  
//  public func sendGuiClientCompletion(_ guiClient: GuiClient) {
//    _clientStream( ClientEvent(.completed, client: guiClient) )
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  
  func statusUpdate(_ status: WanStatus) {
    _statusStream(status)
  }
  
//  func testUpdate(_ result: SmartlinkTestResult) {
//    _testStream(result)
//  }
  
  /// Process an incoming DiscoveryPacket
  /// - Parameter newPacket: the packet
  func processPacket(_ newPacket: Packet) {
    
    // is it a Packet that has been seen previously?
    if let oldPacket = packets[id: newPacket.serial + newPacket.publicIp] {
      // KNOWN PACKET
      updatePacketData(oldPacket, newPacket)

//      if newPacket != oldPacket {
//        // CHANGED KNOWN packet
//        updatePacketData(oldPacket, newPacket)
//        log("\(newPacket.source == .local ? "Local" : "Smartlink") Listener: CHANGED packet, \(newPacket.nickname), \(newPacket.serial)", .info, #function, #file, #line)
//        
//      } else {
//        // UN-CHANGED KNOWN packet (timestamp update)
//        packets[id: newPacket.serial + newPacket.publicIp] = newPacket
//      }
      
    } else {
      // UNKNOWN packet
      updatePacketData(nil, newPacket)
      log("\(newPacket.source == .local ? "Local" : "Smartlink") Listener: NEW packet, \(newPacket.nickname), \(newPacket.serial)", .info, #function, #file, #line)
    }
  }
  
  private func updatePacketData(_ oldPacket: Packet?, _ newPacket: Packet ) {
    // update Packets collection
    packets[id: newPacket.serial + newPacket.publicIp] = newPacket
    
    // identify GuiClient changes
    if oldPacket == nil {
      for guiClient in newPacket.guiClients {
        
        stations.append(Station(packet: newPacket, station: guiClient.station))

//        guiClients[id: guiClient.handle] = guiClient
        
        _clientStream( ClientEvent(.added, client: guiClient))
        log("Listener: guiClient ADDED, \(guiClient.station), \(guiClient.program)", .info, #function, #file, #line)
      }
      
    } else {
      if oldPacket != nil {
        
        for guiClient in newPacket.guiClients {
          if !oldPacket!.guiClients.contains(guiClient){
            
            stations.append(Station(packet: newPacket, station: guiClient.station))

//            guiClients[id: guiClient.handle] = guiClient

            _clientStream( ClientEvent(.added, client: guiClient))
            log("Listener: guiClient ADDED, \(guiClient.station), \(guiClient.program)", .info, #function, #file, #line)
          }
        }
        for guiClient in oldPacket!.guiClients {
          if !newPacket.guiClients.contains(guiClient){
            
            stations.remove(id: oldPacket!.serial + oldPacket!.publicIp + guiClient.station)
            
//            guiClients.remove(id: guiClient.handle)
            
//            if guiClient.station == activeStation {
//              print("----->>>>> Skould disconnect")
//            }

            _clientStream( ClientEvent(.removed, client: guiClient))
            log("Listener: guiClient REMOVED, \(guiClient.station), \(guiClient.program)", .info, #function, #file, #line)
          }
        }
      }
    }
  }
  
  
  /// Remove one or more packets meeting the condition
  /// - Parameter condition: a closure defining the condition
  public func removePackets(condition: @escaping (Packet) -> Bool) {
    _formatter.timeStyle = .long
    _formatter.dateStyle = .none
    for packet in packets where condition(packet) {
      packets.remove(packet)
      log("\(packet.source == .local ? "Local" : "Smartlink") Listener: packet REMOVED, \(packet.nickname) \(packet.serial) @ " + _formatter.string(from: packet.lastSeen), .info, #function, #file, #line)
    }
  }
  
  /// FIndthe first packet meeting the condition
  /// - Parameter condition: a closure defining the condition
  func findPacket(condition: @escaping (Packet) -> Bool) -> Packet? {
    for packet in packets where condition(packet) {
      return packet
    }
    return nil
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
}
