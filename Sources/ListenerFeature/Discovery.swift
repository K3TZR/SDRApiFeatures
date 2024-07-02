//
//  Discovery.swift
//
//
//  Created by Douglas Adams on 5/17/24.
//

import ComposableArchitecture
import Foundation

import SharedFeature


//@MainActor
//@Observable
//final public class Discovery {
//  // ----------------------------------------------------------------------------
//  // MARK: - Singleton
//  
//  public static var shared = Discovery()
//  private init() {}
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Public properties
//
//  public var packets = IdentifiedArrayOf<Packet>()
//  public var stations = IdentifiedArrayOf<Station>()
//  public var guiClients = IdentifiedArrayOf<GuiClient>()
//
//  // ----------------------------------------------------------------------------
//  // MARK: - Public Packet methods
//
//  public func addPacket(_ packet: Packet) {
//    
//  }
//
//  /// FIndthe first packet meeting the condition
//  /// - Parameter condition: a closure defining the condition
//  public func findPacket(condition: @escaping (Packet) -> Bool) -> Packet? {
//    for packet in _packets where condition(packet) {
//      return packet
//    }
//    return nil
//  }
//
//  /// Process an incoming DiscoveryPacket
//  /// - Parameter newPacket: the packet
//  func process(_ newPacket: Packet) {
//    // is it a Packet that has been seen previously?
//    if let oldPacket = _packets[id: newPacket.serial + "|" + newPacket.publicIp] {
//      // KNOWN PACKET
//      update(oldPacket, newPacket)
//      
//    } else {
//      // UNKNOWN packet
//      update(nil, newPacket)
//      log("Packets: packet ADDED, \(newPacket.source == .local ? "Local" : "Smartlink"), \(newPacket.nickname), \(newPacket.serial) ", .info, #function, #file, #line)
//    }
//  }
//
//  public func removePacket(_ packet: Packet) {
//    
//  }
//  
//  /// Remove one or more packets meeting the condition
//  /// - Parameter condition: a closure defining the condition
//  public func removePackets(for condition: @escaping (Packet) -> Bool) {
//    let _formatter = DateFormatter()
//    _formatter.timeStyle = .long
//    _formatter.dateStyle = .none
//    for packet in _packets where condition(packet) {
//      
//      // update Stations
//      for station in stations where condition(station.packet) {
//        stations.remove(station)
//        log("Packets: station REMOVED, \(station.packet.source == .local ? "Local" : "Smartlink"), \(packet.nickname) \(packet.serial) @ " + _formatter.string(from: packet.lastSeen), .info, #function, #file, #line)
//      }
//      // update Packets
//      _packets.remove(packet)
//      log("Packets: packet REMOVED, \(packet.source == .local ? "Local" : "Smartlink"), \(packet.nickname) \(packet.serial) @ " + _formatter.string(from: packet.lastSeen), .info, #function, #file, #line)
//    }
//  }
//
//
//  // ----------------------------------------------------------------------------
//  // MARK: - Public Station methods
//
//  public func addStation(_ station: Station) {
//    
//  }
//  
//  public func removeStation(_ station: String) {
//    
//  }
//
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Private methods
//
//  private func update(_ oldPacket: Packet?, _ newPacket: Packet ) {
//    // update Packets collection
//    _packets[id: newPacket.serial + "|" + newPacket.publicIp] = newPacket
//    
//    // identify GuiClient changes
//    if oldPacket == nil {
//      // completely new packet
//      for guiClient in newPacket.guiClients {
//        
//        stations.append(Station(packet: newPacket, station: guiClient.station))
//
//        guiClients[id: guiClient.handle] = guiClient
//        
////        _clientStream( ClientEvent(.added, client: guiClient))
//        log("Packets: guiClient ADDED, \(guiClient.station), \(guiClient.program)", .info, #function, #file, #line)
//      }
//      
//    } else {
//      if oldPacket != nil {
//        // known packet, added GuiClients
//        for guiClient in newPacket.guiClients {
//          if !oldPacket!.guiClients.contains(guiClient){
//            
//            stations.append(Station(packet: newPacket, station: guiClient.station))
//
//            guiClients[id: guiClient.handle] = guiClient
//
////            _clientStream( ClientEvent(.added, client: guiClient))
//            log("Packets: guiClient ADDED, \(guiClient.station), \(guiClient.program)", .info, #function, #file, #line)
//          }
//        }
//        // known packet, removed GuiClients
//        for guiClient in oldPacket!.guiClients {
//          if !newPacket.guiClients.contains(guiClient){
//            
//            stations.remove(id: oldPacket!.serial + "|" + oldPacket!.publicIp + "|" + guiClient.station + "|" + oldPacket!.nickname + "|" + oldPacket!.source.rawValue)
//            
//            guiClients.remove(id: guiClient.handle)
//            
////            if guiClient.station == activeStation {
////              print("----->>>>> Skould disconnect")
////            }
//
////            _clientStream( ClientEvent(.removed, client: guiClient))
//            log("Packets: guiClient REMOVED, \(guiClient.station), \(guiClient.program)", .info, #function, #file, #line)
//          }
//        }
//      }
//    }
//  }
//
//}
