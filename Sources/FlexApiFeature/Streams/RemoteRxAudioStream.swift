//
//  RemoteRxAudioStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 4/5/23.
//

import Foundation

import SharedFeature
import VitaFeature
import XCGLogFeature

@Observable
public final class RemoteRxAudioStream: Identifiable {
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) {
    self.id = id
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public weak var delegate: RxAudioHandler?

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
  private var _rxLostPacketCount = 0
  private var _rxPacketCount = 0
  private var _rxSequenceNumber = -1

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  ///  Parse RemoteRxAudioStream key/value pairs
  /// - Parameter properties: a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair
    for property in properties {
      // check for unknown Keys
      guard let token = Property(rawValue: property.key) else {
        // log it and ignore the Key
        log("RemoteRxAudioStream \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
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
      log("RemoteRxAudioStream \(id.hex) ADDED: compression = \(compression), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Receive RxRemoteAudioStream audio
  /// - Parameters:
  ///   - vita:               an Opus Vita struct
  public func vitaProcessor(_ vita: Vita) {
    // is this the first packet?
    if _rxSequenceNumber == -1 {
      _rxSequenceNumber = vita.sequence
      _rxPacketCount = 1
      _rxLostPacketCount = 0
    } else {
      _rxPacketCount += 1
    }
    
    // Pass the data frame to the delegate
//    delegate?.streamHandler( RemoteRxAudioFrame(payload: vita.payloadData, numberOfSamples: vita.payloadSize, isCompressed: vita.classCode == .opus) )
    
    delegate?.rxAudioHandler(payload: vita.payloadData,
                             compressed: vita.classCode == .opus)

    // calculate the next Sequence Number
    _rxSequenceNumber = (_rxSequenceNumber + 1) % 16
  }
}


// ----------------------------------------------------------------------------
// MARK: - Stream definitions

//extension RemoteRxAudioStream {
//
//  /// A stream of received RxAudio Messages
//  public var rxAudioStream: AsyncStream<RemoteRxAudioFrame> {
//    AsyncStream { continuation in
//      _rxAudioStream = { frame in
//        continuation.yield(frame)
//      }
//      continuation.onTermination = { @Sendable _ in
//      }
//    }
//  }
//}
