//
//  RemoteTxAudio.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 2/9/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature
import VitaFeature


// RemoteTxAudio
//      creates a RemoteTxAudio instance to be used by a Client to support the
//      processing of a UDP stream of Tx Audio from the client to the Radio. The RemoteTxAudio
//      is added / removed by TCP messages.
@MainActor
@Observable
public final class RemoteTxAudio: Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) { self.id = id }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id : UInt32
  
  public var clientHandle: UInt32 = 0
  public var compression = ""
  public var ip = ""
  
  // ------------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case clientHandle = "client_handle"
    case compression
    case ip
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Instance methods
  
  ///  Parse  key/value pairs
  /// - Parameter properties: a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair
    for property in properties {
      // check for unknown Keys
      guard let token = Property(rawValue: property.key) else {
        // log it and ignore the Key
        apiLog.warning("RemoteTxAudio \(self.id.hex): unknown property, \(property.key) = \(property.value)")
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
        // Note: only supports "opus", not sure why the compression property exists (future?)
        
      case .clientHandle: clientHandle = property.value.handle ?? 0
      case .compression:  compression = property.value.lowercased()
      case .ip:           ip = property.value
      }
    }
    // is it initialized?
    if _initialized == false && clientHandle != 0 {
      // NO, it is now
      _initialized = true
      apiLog.debug("RemoteTxAudio \(self.id.hex) ADDED: handle = \(self.clientHandle.hex)")
    }
  }
}
