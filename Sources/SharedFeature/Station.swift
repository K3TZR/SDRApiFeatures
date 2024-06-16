//
//  Station.swift
//
//
//  Created by Douglas Adams on 6/16/24.
//

import Foundation

//@Observable
//final public class Station: Identifiable, Equatable, Hashable, Comparable {
  public struct Station: Identifiable, Equatable, Hashable, Comparable {
  public var id: String { packet.serial + "|" + packet.publicIp + "|" + station + "|" + packet.nickname + "|" + packet.source.rawValue}
  public static func ==(lhs: Station, rhs: Station) -> Bool {
    lhs.id == rhs.id
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(packet.serial)
    hasher.combine(packet.source)
    hasher.combine(station)
  }
  public static func < (lhs: Station, rhs: Station) -> Bool {
    lhs.station < rhs.station
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(
    packet: Packet,
    station: String = ""
  )
  {
    self.packet = packet
    self.station = station
  }
  
  public var packet: Packet
  public var station: String
}
