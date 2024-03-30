//
//  RemoteRxAudioStream.swift
//  
//
//  Created by Douglas Adams on 4/5/23.
//

import Foundation

import SharedFeature
import VitaFeature
import XCGLogFeature

@Observable
public final class RemoteRxAudioStream: Identifiable, Equatable {
  public static func == (lhs: RemoteRxAudioStream, rhs: RemoteRxAudioStream) -> Bool {
    lhs.id == rhs.id
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ apiModel: ApiModel) {
    self.id = id
    _apiModel = apiModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public var isStreaming = false
  
  public var clientHandle: UInt32 = 0
  public var compression = ""
  public var ip = ""
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
//  public weak var delegate: RawStreamHandler?
  public weak var delegate: RxAudioHandler?

  public enum Compression : String {
    case opus
    case none
  }
  
  public let id: UInt32
  public var initialized = false
 
  public enum Property: String {
    case clientHandle = "client_handle"
    case compression
    case ip
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _apiModel: ApiModel
  private var _rxLostPacketCount = 0
  private var _rxPacketCount = 0
  private var _rxSequenceNumber = -1
  private var _streamStarted = false

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func setIsStreaming() {
    isStreaming = true
  }

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
    if initialized == false && clientHandle != 0 {
      // NO, it is now
      initialized = true
      log("RemoteRxAudioStream \(id.hex) ADDED: compression = \(compression), handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Receive RxRemoteAudioStream audio
  /// - Parameters:
  ///   - vita:               an Opus Vita struct
  public func vitaProcessor(_ vita: Vita) {
    
    if _streamStarted == false {
      _streamStarted = true
      
      // log the start of the stream
      log("RemoteRxAudioStream \(vita.streamId.hex) STARTED: compression = \(vita.classCode == .opus ? "opus" : "none")", .info, #function, #file, #line)
      
      Task { await MainActor.run {  _apiModel.remoteRxAudioStreams[id: vita.streamId]?.isStreaming = true }}
    }
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
