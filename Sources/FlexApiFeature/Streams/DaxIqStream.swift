//
//  DaxIqStream.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 3/9/17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import SharedFeature
import VitaFeature

// DaxIqStream Class implementation
//      creates an DaxIqStream instance to be used by a Client to support the
//      processing of a stream of IQ data from the Radio to the client. DaxIqStream
//      structs are added / removed by the incoming TCP messages. DaxIqStream
//      objects periodically receive IQ data in a UDP stream. They are collected
//      in the Model.daxIqStreams collection.
@Observable
public final class DaxIqStream: Identifiable, Equatable {
  public static func == (lhs: DaxIqStream, rhs: DaxIqStream) -> Bool {
    lhs.id == rhs.id
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) { self.id = id }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
//  public var initialized = false
  public var isStreaming = false

  public var channel = 0
  public var clientHandle: UInt32 = 0
  public var ip = ""
  public var isActive = false
  public var pan: UInt32 = 0
  public var rate = 0

  public var delegate: StreamHandler?
//  public var rxLostPacketCount = 0
  
  public enum Property: String {
    case channel        = "daxiq_channel"
    case clientHandle   = "client_handle"
    case ip
    case isActive       = "active"
    case pan
    case rate           = "daxiq_rate"
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _initialized = false

  private var _rxPacketCount      = 0
  private var _rxLostPacketCount  = 0
  private var _txSampleCount      = 0
  private var _rxSequenceNumber   = -1

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Parse key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      
      guard let token = Property(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        log("DaxIqStream \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle:     clientHandle = property.value.handle ?? 0
      case .channel:          channel = property.value.iValue
      case .ip:               ip = property.value
      case .isActive:         isActive = property.value.bValue
      case .pan:              pan = property.value.streamId ?? 0
      case .rate:             rate = property.value.iValue
      case .type:             break  // included to inhibit unknown token warnings
      }
    }
    // is it initialized?
    if _initialized == false && clientHandle != 0 {
      // NO, it is now
      _initialized = true
      log("DaxIqStream \(id.hex) ADDED: channel = \(channel)", .debug, #function, #file, #line)
    }
  }

  
  
  
  
  
  
  
  
  
  
  /// Set a property
  /// - Parameters:
  ///   - radio:      the current radio
  ///   - id:         a DaxIqStream Id
  ///   - property:   a DaxIqStream Token
  ///   - value:      the new value
  public static func setProperty(_ property: Property, value: Any) {
    // FIXME: add commands
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Static methods
  
  
  /// Send a command to Set a DaxIqStream property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified DaxIqStream
  ///   - token:      the parse token
  ///   - value:      the new value
  private static func send(_ token: Property, _ value: Any) {
    // FIXME: add commands
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Process the IqStream Vita struct
  /// - Parameters:
  ///   - vita:       a Vita struct
  public func vitaProcessor(_ vita: Vita) {
    if isStreaming == false {
      isStreaming = true
      // log the start of the stream
      log("DaxIq: stream \(id.hex) STARTED:", .info, #function, #file, #line)
    }
    // is this the first packet?
    if _rxSequenceNumber == -1 {
      _rxSequenceNumber = vita.sequence
      _rxPacketCount = 1
      _rxLostPacketCount = 0
    } else {
      _rxPacketCount += 1
    }
    
    switch (_rxSequenceNumber, vita.sequence) {
      
    case (let expected, let received) where received < expected:
      // from a previous group, ignore it
      log("DaxIqStream, delayed frame(s) ignored: expected \(expected), received \(received)", .warning, #function, #file, #line)
      return
      
    case (let expected, let received) where received > expected:
      _rxLostPacketCount += 1
      
      // from a later group, jump forward
      let lossPercent = String(format: "%04.2f", (Float(_rxLostPacketCount)/Float(_rxPacketCount)) * 100.0 )
      log("DaxIqStream, missing frame(s) skipped: expected \(expected), received \(received), loss = \(lossPercent) %", .warning, #function, #file, #line)
      
      _rxSequenceNumber = received
      fallthrough
      
    default:
      // received == expected
      // calculate the next Sequence Number
      _rxSequenceNumber = (_rxSequenceNumber + 1) % 16
      
      // Pass the data frame to the delegate
      delegate?.streamHandler( DaxIqStreamFrame(payload: vita.payloadData, numberOfBytes: vita.payloadSize, daxIqChannel: channel ))
    }
  }
}
