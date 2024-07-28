//
//  RemoteRxAudio.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 4/5/23.
//

import Foundation

import AudioFeature
import SharedFeature
import VitaFeature


// RemoteRxAudio
//      creates a RemoteRxAudio instance to be used by a Client to support the
//      processing of a UDP stream of Rx Audio from the Radio to the client. The RemoteRxAudio
//      is added / removed by TCP messages.

@MainActor
@Observable
public final class RemoteRxAudio: Identifiable {
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ objectModel: ObjectModel) {
    self.id = id
    _objectModel = objectModel
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  
  public var clientHandle: UInt32 = 0
  public var compression = ""
  public var ip = ""
  
  // ----------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Compression : String {
    case opus
    case none
  }
  
  public enum Property: String {
    case clientHandle = "client_handle"
    case compression
    case ip
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false
  private let _objectModel: ObjectModel
  private var _rxLostPacketCount = 0
  private var _rxPacketCount = 0
  private var _rxSequenceNumber = -1
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  ///  Parse RemoteRxAudio key/value pairs
  /// - Parameter properties: a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair
    for property in properties {
      // check for unknown Keys
      guard let token = Property(rawValue: property.key) else {
        // log it and ignore the Key
        apiLog.warning("RemoteRxAudio \(self.id.hex): unknown property, \(property.key) = \(property.value)")
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .clientHandle: clientHandle = property.value.handle ?? 0
      case .compression:  compression = property.value.lowercased()
      case .ip:           ip = property.value
      }
    }
    // is it initialized?
    if _initialized == false && clientHandle != 0 {
      // NO, it is now
      _initialized = true
      apiLog.debug("RemoteRxAudio \(self.id.hex) ADDED: compression = \(self.compression), handle = \(self.clientHandle.hex)")
    }
  }
}
