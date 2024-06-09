//
//  DaxMicAudio.swift
//  FlexApiFeature/Objects
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import AudioFeature
import SharedFeature
import VitaFeature
import XCGLogFeature

// DaxMicAudio
//      creates a DaxMicAudio instance to be used by a Client to support the
//      processing of a UDP stream of Mic Audio from the Radio to the client. The DaxMicAudio
//      is added / removed by TCP messages.
@MainActor
@Observable
public final class DaxMicAudio: Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) { self.id = id }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var audioOutput: RxAudioPlayer?

  public var clientHandle: UInt32 = 0
  public var ip = ""
  public var micGain = 0 {
    didSet { if micGain != oldValue {
      var newGain = micGain
      // check limits
      if newGain > 100 { newGain = 100 }
      if newGain < 0 { newGain = 0 }
      if micGain != newGain {
        micGain = newGain
        if micGain == 0 {
          micGainScalar = 0.0
          return
        }
        let db_min:Float = -10.0;
        let db_max:Float = +10.0;
        let db:Float = db_min + (Float(micGain) / 100.0) * (db_max - db_min);
        micGainScalar = pow(10.0, db / 20.0);
      }
    }}}
  public internal(set) var micGainScalar: Float = 0
  
  // ------------------------------------------------------------------------------
  // MARK: - Public types
  
  public enum Property: String {
    case clientHandle = "client_handle"
    case ip
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false
  private var _rxLostPacketCount = 0
  private var _rxPacketCount = 0
  private var _rxSequenceNumber = -1
  private var _streamActive = false

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  /// Parse key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown keys
      guard let token = Property(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        log("DaxMicAudio \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle: clientHandle = property.value.handle ?? 0
      case .ip:           ip = property.value
      case .type:         break  // included to inhibit unknown token warnings
      }
    }
    // is it initialized?
    if _initialized == false && clientHandle != 0 {
      // NO, it is now
      _initialized = true
      log("DaxMicAudio \(id.hex) ADDED: handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }
}
