//
//  DaxMicAudioStream.swift
//  FlexApiFeature/Objects
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import SharedFeature
import VitaFeature
import XCGLogFeature

// DaxMicAudioStream
//      creates a DaxMicAudioStream instance to be used by a Client to support the
//      processing of a stream of Mic Audio from the Radio to the client. DaxMicAudioStream
//      instances are added / removed by the incoming TCP messages. DaxMicAudioStream
//      instances periodically receive Mic Audio in a UDP stream. They are collected
//      in the Model.daxMicAudioStreams collection.
@Observable
public final class DaxMicAudioStream: Identifiable, Equatable {
  public static func == (lhs: DaxMicAudioStream, rhs: DaxMicAudioStream) -> Bool {
    lhs.id == rhs.id
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) { self.id = id }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var initialized = false
  public var isStreaming = false

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
  
  public var delegate: DaxAudioOutputHandler?
//  public var rxLostPacketCount = 0
  
  public enum Property: String {
    case clientHandle = "client_handle"
    case ip
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties

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
        log("DaxMicAudioStream \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
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
    if initialized == false && clientHandle != 0 {
      // NO, it is now
      initialized = true
      log("DaxMicAudioStream \(id.hex) ADDED: handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public Command methods
  
  /// Set a property
  /// - Parameters:
  ///   - radio:      the current radio
  ///   - id:         an Amplifier Id
  ///   - property:   an Amplifier Token
  ///   - value:      the new value
  public static func setProperty(radio: Radio, _ id: UInt32, property: Property, value: Any) {
    // FIXME: add commands
  }
  
  /// Send a command to Set a DaxMicAudioStream property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified DaxMicAudioStream
  ///   - token:      the parse token
  ///   - value:      the new value
  private static func send(_ radio: Radio, _ id: UInt32, _ token: Property, _ value: Any) {
    // FIXME: add commands
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  /// Process the DaxAudioStream Vita struct
  /// - Parameters:
  ///   - vita:       a Vita struct
//  public func vitaProcessor(_ vita: Vita) {
//    if isStreaming == false {
//      isStreaming = true
//      // log the start of the stream
//      log("DaxMicAudioStream \(id.hex) STARTED:", .info, #function, #file, #line)
//    }
//    delegate?.daxAudioHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxReducedBw, channelNumber: nil)
//  }

  /// Process the Mic Audio Stream Vita struct
  /// - Parameters:
  ///   - vitaPacket:         a Vita struct
//  public func vitaProcessor(_ vita: Vita) {
//    if _streamActive == false {
//      _streamActive = true
//      // log the start of the stream
//      log("DaxMicAudio: stream  \(id.hex) STARTED:", .info, #function, #file, #line)
//      Task {
//        await MainActor.run { isStreaming = true }
//      }
//    }
//    // is this the first packet?
//    if _rxSequenceNumber == -1 {
//      _rxSequenceNumber = vita.sequence
//      _rxPacketCount = 1
//      _rxLostPacketCount = 0
//    } else {
//      _rxPacketCount += 1
//    }
//    
//    switch (_rxSequenceNumber, vita.sequence) {
//      
//    case (let expected, let received) where received < expected:
//      // from a previous group, ignore it
//      log("DaxMicAudioStream delayed frame(s) ignored: expected \(expected), received \(received)", .warning, #function, #file, #line)
//      return
//      
//    case (let expected, let received) where received > expected:
//      _rxLostPacketCount += 1
//      
//      // from a later group, jump forward
//      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
//      log("DaxMicAudioStream missing frame(s) skipped: expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)
//      
//      _rxSequenceNumber = received
//      fallthrough
//      
//    default:
//      // received == expected
//      // calculate the next Sequence Number
//      _rxSequenceNumber = (_rxSequenceNumber + 1) % 16
//      
//      if vita.classCode == .daxReducedBw {
//        delegate?.streamHandler( DaxRxReducedAudioFrame(payload: vita.payloadData, numberOfSamples: vita.payloadSize / 2 ))
//        
//      } else {
//        delegate?.streamHandler( DaxRxAudioFrame(payload: vita.payloadData, numberOfFrames: vita.payloadSize / (4 * 2) ))
//      }
//    }
//  }
}
