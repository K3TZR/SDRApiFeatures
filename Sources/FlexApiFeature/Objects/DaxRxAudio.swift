//
//  DaxRxAudio.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 2/24/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import AudioFeature
import SharedFeature
import VitaFeature
//import XCGLogFeature

// DaxRxAudio
//      creates a DaxRxAudio instance to be used by a Client to support the
//      processing of a UDP stream of Rx Audio from the Radio to the client. THe DaxRxAudio
//      is added / removed by TCP messages. 
@MainActor
@Observable
public final class DaxRxAudio: Identifiable {
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) { self.id = id }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var audioOutput: RxAudioPlayer?

  public var clientHandle: UInt32 = 0
  public var ip = ""
  public var sliceLetter = ""
  public var daxChannel = 0
  public var rxGain = 0
    
  // ------------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case clientHandle   = "client_handle"
    case daxChannel     = "dax_channel"
    case ip
    case sliceLetter    = "slice"
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false
  private var _rxPacketCount      = 0
  private var _rxLostPacketCount  = 0
  private var _rxSequenceNumber   = -1

  private static let elementSizeStandard = MemoryLayout<Float>.size
  private static let elementSizeReduced = MemoryLayout<Int16>.size
  private static let channelCount = 2
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Parse key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    for property in properties {
      // check for unknown keys
      guard let token = Property(rawValue: property.key) else {
        // unknown, log it and ignore the Key
        apiLog.warning("DaxRxAudio \(self.id.hex): unknown property, \(property.key) = \(property.value)")
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: clientHandle = property.value.handle ?? 0
      case .daxChannel:   daxChannel = property.value.iValue
      case .ip:           ip = property.value
      case .sliceLetter:  sliceLetter = property.value
//        // do we have a good reference to the GUI Client?
//        if let handle = radio.findHandle(for: radio.boundClientId) {
//          // YES,
//          self.slice = radio.findSlice(letter: property.value, guiClientHandle: handle)
//          let gain = rxGain
//          rxGain = 0
//          rxGain = gain
//        } else {
//          // NO, clear the Slice reference and carry on
//          slice = nil
//          continue
//        }

      case .type:         break  // included to inhibit unknown token warnings
      }
    }
    // is it initialized?
    if _initialized == false && clientHandle != 0 {
      // NO, it is now
      _initialized = true
      apiLog.debug("DaxRxAudio \(self.id.hex) ADDED: channel = \(self.daxChannel), handle = \(self.clientHandle.hex)")
    }
  }
}
