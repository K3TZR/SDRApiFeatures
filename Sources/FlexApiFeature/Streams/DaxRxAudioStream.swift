//
//  DaxRxAudioStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 2/24/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import AudioFeature
import SharedFeature
import VitaFeature
import XCGLogFeature

// DaxRxAudioStream
//      creates a DaxRxAudioStream instance to be used by a Client to support the
//      processing of a UDP stream of Rx Audio from the Radio to the client. THe DaxRxAudioStream
//      is added / removed by TCP messages. 
@Observable
public final class DaxRxAudioStream: Identifiable, StreamProcessor {
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
        log("DaxRxAudioStream \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
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
      log("DaxRxAudioStream \(id.hex) ADDED: channel = \(daxChannel), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }
  
  
  
  public func streamProcessor(_ vita: Vita) {
//    if audioOutput == nil {
//      audioOutput = RxAudioPlayer(streamId: vita.streamId)
//      audioOutput?.start()
//    }
//   audioOutput?.audioProcessor(vita)
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public set property methods
  
  /// Set a property
  /// - Parameters:
  ///   - radio:      the current radio
  ///   - id:         a DaxRxAudioStream Id
  ///   - property:   a DaxRxAudioStream Token
  ///   - value:      the new value
  public static func setProperty(_ property: Property, value: Any) {
    // FIXME: add commands
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  /// Send a command to Set a DaxRxAudioStream property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified DaxRxAudioStream
  ///   - token:      the parse token
  ///   - value:      the new value
  private static func send(_ token: Property, _ value: Any) {
    // FIXME: add commands
  }
}
