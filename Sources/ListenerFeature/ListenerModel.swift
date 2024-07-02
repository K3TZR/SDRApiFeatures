//
//  Listener.swift
//  FlexApiFeature/Listener
//
//  Created by Douglas Adams on 11/26/22.
//

import ComposableArchitecture
import Foundation

import SharedFeature


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
  
  // accessed by a View therefore must be @MainActor
//  @MainActor public var activePacket: Packet?
//  @MainActor public var activeStation: String?
  @MainActor public var packets = IdentifiedArrayOf<Packet>()
  public var smartlinkTestResult = SmartlinkTestResult()
  @MainActor public var stations = IdentifiedArrayOf<Station>()

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
  
//  public func setActive(_ isGui: Bool, _ selection: String, _ directMode: Bool = false) {
//    Task {
//      await MainActor.run {
//        if directMode {
//          
//          let components = selection.components(separatedBy: "|")
//          let serial = components[0]
//          let publicIp = components[1]
//          
//          if isGui {
//            activePacket = Packet(nickname: "DIRECT", serial: serial, publicIp: publicIp, port: 4_992)
//            activeStation = "SDRApi"
//          } else {
//            fatalError()
//          }
//          
//        } else {
//          if isGui {
//            activePacket = packets[id: selection]!
//            activeStation = "SDRApi"
//          } else {
//            activePacket  = stations[id: selection]!.packet
//            activeStation = stations[id: selection]!.station
//          }
//        }
//      }
//    }
//  }
    
  public func localMode(_ enable: Bool) {
    _localListener?.stop()
    _localListener = nil
    
    if enable {
      _localListener = LocalListener(self)
      _localListener!.start()
    } else {
      Task { await removePackets(condition: {$0.source == .local}) }
    }
  }
  
  public func smartlinkMode(_ user: String = "", _ loginRequired: Bool = false, _ previousIdToken: String, _ refreshToken: String) async -> Tokens {
    _smartlinkListener?.stop()
    _smartlinkListener = nil
    
    _smartlinkListener = SmartlinkListener(self)
    let tokens = await _smartlinkListener!.start(Tokens(previousIdToken, refreshToken))
    if !tokens.idToken.isEmpty {
      apiLog.debug("Smartlink Listener: STARTED")
      return tokens
    } else {
      _smartlinkListener = nil
      return Tokens("", "")
    }
  }
  
  public func smartlinkStart(_ user: String, _ pwd: String) async -> Tokens {
    _smartlinkListener = SmartlinkListener(self)
    let tokens = await _smartlinkListener!.start(user: user, pwd: pwd)
    if !tokens.idToken.isEmpty {
      apiLog.debug("Smartlink Listener: Login SUCCESS")
      return tokens
    } else {
      apiLog.debug("Smartlink Listener: Login FAILURE")
      _smartlinkListener = nil
      return Tokens("", "")
    }
  }
  
  public func smartlinkStop() {
    Task { await removePackets(condition: {$0.source == .smartlink})  }

    _smartlinkListener?.stop()
    _smartlinkListener = nil
  }
  
  /// Send a Test message
  /// - Parameter serial:     radio serial number
  /// - Returns:              success / failure
  public func smartlinkTest(_ selection: String) {
    let serial = selection.prefix(19)
    apiLog.debug("Smartlink Listener: test initiated to serial number, \(serial)")
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
      apiLog.debug("Smartlink Listener: Connect sent to serial \(serial)")
      // send a command to SmartLink to request a connection to the specified Radio
      _smartlinkListener?.sendTlsCommand("application connect serial=\(serial) hole_punch_port=\(holePunchPort))")
    }
  }
  
  /// Disconnect a smartlink Radio
  /// - Parameter serialNumber:         the serial number of the Radio
  public func smartlinkDisconnect(for serial: String) {
    apiLog.debug("Smartlink Listener: Disconnect sent to serial \(serial)")
    // send a command to SmartLink to request disconnection from the specified Radio
    _smartlinkListener?.sendTlsCommand("application disconnect_users serial=\(serial)")
  }
  
  /// Disconnect a single smartlink Client
  /// - Parameters:
  ///   - serialNumber:         the serial number of the Radio
  ///   - handle:               the handle of the Client
  public func smartlinkDisconnectClient(for serial: String, handle: UInt32) {
    apiLog.debug("Smartlink Listener: Disconnect sent to serial \(serial), handle \(handle.hex)")
    // send a command to SmartLink to request disconnection from the specified Radio
    _smartlinkListener?.sendTlsCommand("application disconnect_users serial=\(serial) handle=\(handle.hex)")
  }
  
  public func isValidDefault(for guiDefault: String?, _ nonGuiDefault: String?, _ isGui: Bool) async -> Bool {
    if isGui {
      guard guiDefault != nil else { return false }
      return await packets[id: guiDefault!] != nil
      
    } else {
      guard nonGuiDefault != nil else { return false }
      return await stations[id: nonGuiDefault!] != nil
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
  @MainActor func process(_ newPacket: Packet) {
    
    // is it a Packet that has been seen previously?
    if let oldPacket = packets[id: newPacket.serial + "|" + newPacket.publicIp] {
      // KNOWN PACKET
      updatePacketData(oldPacket, newPacket)
      
    } else {
      // UNKNOWN packet
      updatePacketData(nil, newPacket)
      apiLog.info("\(newPacket.source == .local ? "Local" : "Smartlink") Listener: NEW packet, \(newPacket.nickname), \(newPacket.serial)")
    }
  }
  
  @MainActor private func updatePacketData(_ oldPacket: Packet?, _ newPacket: Packet ) {
    // update Packets collection
    packets[id: newPacket.serial + "|" + newPacket.publicIp] = newPacket
    
    // identify GuiClient changes
    if oldPacket == nil {
      for guiClient in newPacket.guiClients {
        
        stations.append(Station(packet: newPacket, station: guiClient.station))

//        guiClients[id: guiClient.handle] = guiClient
        
        _clientStream( ClientEvent(.added, client: guiClient))
        apiLog.info("Listener: guiClient ADDED, \(guiClient.station), \(guiClient.program)")
      }
      
    } else {
      if oldPacket != nil {
        
        for guiClient in newPacket.guiClients {
          if !oldPacket!.guiClients.contains(guiClient){
            
            stations.append(Station(packet: newPacket, station: guiClient.station))

//            guiClients[id: guiClient.handle] = guiClient

            _clientStream( ClientEvent(.added, client: guiClient))
            apiLog.info("Listener: guiClient ADDED, \(guiClient.station), \(guiClient.program)")
          }
        }
        for guiClient in oldPacket!.guiClients {
          if !newPacket.guiClients.contains(guiClient){
            
            stations.remove(id: oldPacket!.serial + "|" + oldPacket!.publicIp + "|" + guiClient.station + "|" + oldPacket!.nickname + "|" + oldPacket!.source.rawValue)
            
//            guiClients.remove(id: guiClient.handle)
            
//            if guiClient.station == activeStation {
//              print("----->>>>> Skould disconnect")
//            }

            _clientStream( ClientEvent(.removed, client: guiClient))
            apiLog.info("Listener: guiClient REMOVED, \(guiClient.station), \(guiClient.program)")
          }
        }
      }
    }
  }
  
  
  /// Remove one or more packets meeting the condition
  /// - Parameter condition: a closure defining the condition
  @MainActor public func removePackets(condition: @escaping (Packet) -> Bool) {
    for packet in packets where condition(packet) {
      
      let timeStamp = packet.lastSeen.formatted(date: .omitted, time: .complete)
      // update Stations
      for station in stations where condition(station.packet) {
        stations.remove(station)
        apiLog.info("\(station.packet.source == .local ? "Local" : "Smartlink") Listener: station REMOVED, \(packet.nickname) \(packet.serial) @ \(timeStamp )")
      }
      // update Packets
      packets.remove(packet)
      apiLog.info("\(packet.source == .local ? "Local" : "Smartlink") Listener: packet REMOVED, \(packet.nickname) \(packet.serial) @ \(timeStamp)")
    }
  }
  
  /// FIndthe first packet meeting the condition
  /// - Parameter condition: a closure defining the condition
  @MainActor func findPacket(condition: @escaping (Packet) -> Bool) -> Packet? {
    for packet in packets where condition(packet) {
      return packet
    }
    return nil
  }
}
