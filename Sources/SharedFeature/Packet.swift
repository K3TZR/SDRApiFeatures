//
//  Packet.swift
//  SharedFeatures/Shared
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import IdentifiedCollections

// ----------------------------------------------------------------------------
// MARK: - Public structs and enums

public enum PacketSource: String, Equatable {
  case direct = "Direct"
  case local = "Local"
  case smartlink = "Smartlink"
}

public enum PacketAction: String {
  case added
  case removed
  case updated
}

public struct PacketEvent {
//public struct PacketEvent: Equatable {
  public var action: PacketAction
  public var packet: Packet
  
  public init(_ action: PacketAction, packet: Packet) {
    self.action = action
    self.packet = packet
  }
}

//public struct Pickable: Identifiable, Equatable {
//  public var id: UUID
//  public var packetId: String     // ID from packets
//  public var name: String
//  public var source: String
//  public var status: String
//  public var station: String
//  public var isDefault: Bool
//  
//  public init(
//    packetId: String,
//    name: String,
//    source: String,
//    status: String,
//    station: String,
//    isDefault: Bool
//  )
//  {
//    self.id = UUID()
//    self.packetId = packetId
//    self.name = name
//    self.source = source
//    self.status = status
//    self.station = station
//    self.isDefault = isDefault
//  }
//}

@Observable
final public class Station: Identifiable, Equatable, Hashable {
//public struct Station: Identifiable, Equatable, Hashable {
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(packet.serial)
    hasher.combine(packet.source)
    hasher.combine(station)
  }

  public static func ==(lhs: Station, rhs: Station) -> Bool {
    lhs === rhs
  }

//  public static func ==(lhs: Station, rhs: Station) -> Bool {
//    // same Serial Number, Public IP and Station
//    guard lhs.packet.serial == rhs.packet.serial && lhs.packet.publicIp == rhs.packet.publicIp && lhs.station == rhs.station else { return false }
//    guard lhs.packet.guiClients == rhs.packet.guiClients else { return false }
//    guard lhs.packet.status == rhs.packet.status else { return false }
//    guard lhs.packet.port == rhs.packet.port else { return false }
//    guard lhs.packet.inUseHost == rhs.packet.inUseHost else { return false }
//    guard lhs.packet.inUseIp == rhs.packet.inUseIp else { return false }
//    guard lhs.packet.publicIp == rhs.packet.publicIp else { return false }
//    guard lhs.packet.publicTlsPort == rhs.packet.publicTlsPort else { return false }
//    guard lhs.packet.publicUdpPort == rhs.packet.publicUdpPort else { return false }
//    guard lhs.packet.publicUpnpTlsPort == rhs.packet.publicUpnpTlsPort else { return false }
//    guard lhs.packet.publicUpnpUdpPort == rhs.packet.publicUpnpUdpPort else { return false }
//    guard lhs.packet.callsign == rhs.packet.callsign else { return false }
//    guard lhs.packet.model == rhs.packet.model else { return false }
//    guard lhs.packet.nickname == rhs.packet.nickname else { return false }
//    return true
//  }
  
  public init(
    packet: Packet,
    station: String = ""
  ) 
  {
    self.packet = packet
    self.station = station
  }
  
  public var id: String { packet.serial + packet.publicIp + station }
  public var packet: Packet
  public var station: String
}

// ----------------------------------------------------------------------------
// MARK: - Packet struct

@Observable
final public class Packet: Identifiable, Equatable, Hashable {
//public struct Packet: Identifiable, Equatable, Hashable {
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(serial)
    hasher.combine(source)
  }
  
  public static func ==(lhs: Packet, rhs: Packet) -> Bool {
    lhs === rhs
  }
//  public static func ==(lhs: Packet, rhs: Packet) -> Bool {
//    // same Serial Number and Public IP
//    guard lhs.serial == rhs.serial && lhs.publicIp == rhs.publicIp else { return false }
//    guard lhs.guiClients == rhs.guiClients else { return false }
//    guard lhs.status == rhs.status else { return false }
//    guard lhs.port == rhs.port else { return false }
//    guard lhs.inUseHost == rhs.inUseHost else { return false }
//    guard lhs.inUseIp == rhs.inUseIp else { return false }
//    guard lhs.publicIp == rhs.publicIp else { return false }
//    guard lhs.publicTlsPort == rhs.publicTlsPort else { return false }
//    guard lhs.publicUdpPort == rhs.publicUdpPort else { return false }
//    guard lhs.publicUpnpTlsPort == rhs.publicUpnpTlsPort else { return false }
//    guard lhs.publicUpnpUdpPort == rhs.publicUpnpUdpPort else { return false }
//    guard lhs.callsign == rhs.callsign else { return false }
//    guard lhs.model == rhs.model else { return false }
//    guard lhs.nickname == rhs.nickname else { return false }
//    return true
//  }
  
  public init(source: PacketSource = .local,
              nickname: String = "",
              serial: String = "",
              publicIp: String = "",
              status: String = ""
  ) {
    lastSeen = Date() // now
    self.source = source
    self.nickname = nickname
    self.serial = serial
    self.publicIp = publicIp
    self.status = status
  }
 
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // these fields are NOT in the received packet but are in the Packet struct
  //  @Published public var guiClients = IdentifiedArrayOf<GuiClient>()
  public var guiClients = IdentifiedArrayOf<GuiClient>()
  
  public var id: String { serial + publicIp }
  public var isPortForwardOn = false
  public var lastSeen: Date
  public var localInterfaceIP = ""
  public var negotiatedHolePunchPort = 0
  public var requiresHolePunch = false
  public var source: PacketSource
//  public var wanHandle = ""
  
  // PACKET TYPE                                       LAN   WAN
  
  // these fields in the received packet ARE COPIED to the Packet struct
  public var callsign = ""                          //  X     X
  public var guiClientHosts = ""                    //  X     X
  public var guiClientStations = ""                 //  X     X
  public var inUseHost = ""                         //  X     X
  public var inUseIp = ""                           //  X     X
  public var model = ""                             //  X     X
  public var nickname = ""                          //  X     X   in WAN as "radio_name"
  public var port = 0                               //  X
  public var publicIp = ""                          //  X     X   in LAN as "ip"
  public var publicTlsPort: Int?                    //        X
  public var publicUdpPort: Int?                    //        X
  public var publicUpnpTlsPort: Int?                //        X
  public var publicUpnpUdpPort: Int?                //        X
  public var serial = ""                            //  X     X
  public var status = ""                            //  X     X
  public var upnpSupported = false                  //        X
  public var version = ""                           //  X     X
  
  // these fields in the received packet ARE NOT COPIED to the Packet struct
  //  public var availableClients = 0                 //  X         ignored
  //  public var availablePanadapters = 0             //  X         ignored
  //  public var availableSlices = 0                  //  X         ignored
  //  public var discoveryProtocolVersion = ""        //  X         ignored
  //  public var fpcMac = ""                          //  X         ignored
  //  public var guiClientHandles = ""                //  X     X   ignored
  //  public var guiClientPrograms = ""               //  X     X   ignored
  //  public var guiClientStations = ""               //  X     X   ignored
  //  public var guiClientIps = ""                    //  X     X   ignored
  //  public var licensedClients = 0                  //  X         ignored
  //  public var maxLicensedVersion = ""              //  X     X   ignored
  //  public var maxPanadapters = 0                   //  X         ignored
  //  public var maxSlices = 0                        //  X         ignored
  //  public var radioLicenseId = ""                  //  X     X   ignored
  //  public var requiresAdditionalLicense = false    //  X     X   ignored
  //  public var wanConnected = false                 //  X         ignored
  
  // ----------------------------------------------------------------------------
  // MARK: - Private enums
  
  private enum DiscoveryTokens : String {
    case lastSeen                   = "last_seen"
    
    case availableClients           = "available_clients"
    case availablePanadapters       = "available_panadapters"
    case availableSlices            = "available_slices"
    case callsign
    case discoveryProtocolVersion   = "discovery_protocol_version"
    case version                    = "version"
    case fpcMac                     = "fpc_mac"
    case guiClientHandles           = "gui_client_handles"
    case guiClientHosts             = "gui_client_hosts"
    case guiClientIps               = "gui_client_ips"
    case guiClientPrograms          = "gui_client_programs"
    case guiClientStations          = "gui_client_stations"
    case inUseHost                  = "inuse_host"
    case inUseHostWan               = "inusehost"
    case inUseIp                    = "inuse_ip"
    case inUseIpWan                 = "inuseip"
    case licensedClients            = "licensed_clients"
    case maxLicensedVersion         = "max_licensed_version"
    case maxPanadapters             = "max_panadapters"
    case maxSlices                  = "max_slices"
    case model
    case nickname                   = "nickname"
    case port
    case publicIp                   = "ip"
    case publicIpWan                = "public_ip"
    case publicTlsPort              = "public_tls_port"
    case publicUdpPort              = "public_udp_port"
    case publicUpnpTlsPort          = "public_upnp_tls_port"
    case publicUpnpUdpPort          = "public_upnp_udp_port"
    case radioLicenseId             = "radio_license_id"
    case radioName                  = "radio_name"
    case requiresAdditionalLicense  = "requires_additional_license"
    case serial                     = "serial"
    case status
    case upnpSupported              = "upnp_supported"
    case wanConnected               = "wan_connected"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Static Public methods
  
  public static func populate(_ properties: KeyValuesArray) -> Packet {
    var guiClientHandles = ""
    var guiClientPrograms = ""
//    var guiClientStations = ""
    var guiClientIps = ""

    // create a minimal packet with now as "lastSeen"
    let packet = Packet()
    
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = DiscoveryTokens(rawValue: property.key) else {
        // log it and ignore the Key
#if DEBUG
        fatalError("Discovery: Unknown property - \(property.key) = \(property.value)")
#else
        continue
#endif
      }
      switch token {
        
        // these fields in the received packet are copied to the Packet struct
      case .callsign:                   packet.callsign = property.value
      case .guiClientHandles:           guiClientHandles = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientHosts:             packet.guiClientHosts = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientIps:               guiClientIps = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientPrograms:          guiClientPrograms = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientStations:          packet.guiClientStations = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .inUseHost, .inUseHostWan:   packet.inUseHost = property.value
      case .inUseIp, .inUseIpWan:       packet.inUseIp = property.value
      case .model:                      packet.model = property.value
      case .nickname, .radioName:       packet.nickname = property.value
      case .port:                       packet.port = property.value.iValue
      case .publicIp, .publicIpWan:     packet.publicIp = property.value
      case .publicTlsPort:              packet.publicTlsPort = property.value.iValueOpt
      case .publicUdpPort:              packet.publicUdpPort = property.value.iValueOpt
      case .publicUpnpTlsPort:          packet.publicUpnpTlsPort = property.value.iValueOpt
      case .publicUpnpUdpPort:          packet.publicUpnpUdpPort = property.value.iValueOpt
      case .serial:                     packet.serial = property.value
      case .status:                     packet.status = property.value
      case .upnpSupported:              packet.upnpSupported = property.value.bValue
      case .version:                    packet.version = property.value
        
        // these fields in the received packet are NOT copied to the Packet struct
      case .availableClients:           break // ignored
      case .availablePanadapters:       break // ignored
      case .availableSlices:            break // ignored
      case .discoveryProtocolVersion:   break // ignored
      case .fpcMac:                     break // ignored
      case .licensedClients:            break // ignored
      case .maxLicensedVersion:         break // ignored
      case .maxPanadapters:             break // ignored
      case .maxSlices:                  break // ignored
      case .radioLicenseId:             break // ignored
      case .requiresAdditionalLicense:  break // ignored
      case .wanConnected:               break // ignored
        
        // satisfy the switch statement
      case .lastSeen:                   break
      }
    }
    
    if guiClientPrograms != "" && packet.guiClientStations != "" && guiClientHandles != "" {
      
      let programs  = guiClientPrograms.components(separatedBy: ",")
      let stations  = packet.guiClientStations.components(separatedBy: ",")
      let handles   = guiClientHandles.components(separatedBy: ",")
      let ips       = guiClientIps.components(separatedBy: ",")
      
      if programs.count == handles.count && stations.count == handles.count && ips.count == handles.count {
        
        for i in 0..<handles.count {
          // add/update if valid fields
          if let handle = handles[i].handle, stations[i] != "", programs[i] != "" , ips[i] != "" {
            // add/update the collection
            packet.guiClients[id: handle] = GuiClient(handle: handle,
                                                      station: stations[i],
                                                      program: programs[i],
                                                      ip: ips[i])
          }
        }
      }
    }
    return packet
  }
}
