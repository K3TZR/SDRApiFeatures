//
//  StreamModel.swift
//
//
//  Created by Douglas Adams on 3/22/24.
//

import IdentifiedCollections
import Foundation

import SharedFeature
import UdpFeature
import VitaFeature
import XCGLogFeature

public enum StreamType: String {
  case daxIqStream = "dax_iq"
  case daxMicAudioStream = "dax_mic"
  case daxRxAudioStream = "dax_rx"
  case daxTxAudioStream = "dax_tx"
  case panadapter = "pan"
  case remoteRxAudioStream = "remote_audio_rx"
  case remoteTxAudioStream = "remote_audio_tx"
  case waterfall
}

final public class StreamStatus: ObservableObject, Identifiable {
  public var type: Vita.ClassCode
  public var name: String
  @Published public var packets = 0
  @Published public var errors = 0
  
  public var id: Vita.ClassCode { type }
  
  public init(_ type: Vita.ClassCode) {
    self.type = type
    name = type.description()
  }
}


@Observable
final public class StreamStatistics {

  public static var shared = StreamStatistics()
  private init() {}

  public var stats: IdentifiedArrayOf<StreamStatus> = [
    StreamStatus(Vita.ClassCode.daxAudio),
    StreamStatus(Vita.ClassCode.daxAudioReducedBw),
    StreamStatus(Vita.ClassCode.daxIq24),
    StreamStatus(Vita.ClassCode.daxIq48),
    StreamStatus(Vita.ClassCode.daxIq96),
    StreamStatus(Vita.ClassCode.daxIq192),
    StreamStatus(Vita.ClassCode.meter),
    StreamStatus(Vita.ClassCode.opus),
    StreamStatus(Vita.ClassCode.panadapter),
    StreamStatus(Vita.ClassCode.waterfall),
  ]
}

@Observable
final public class StreamModel: StreamDistributor {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton

  public static var shared = StreamModel()
  private init() {
    Udp.shared.delegate = self
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var meterStream: MeterStream?
  
  public var daxIqStreams = IdentifiedArrayOf<DaxIqStream>()
  public var daxRxAudioStreams = IdentifiedArrayOf<DaxRxAudioStream>()
  public var daxTxAudioStreams = IdentifiedArrayOf<DaxTxAudioStream>()
  public var daxMicAudioStreams = IdentifiedArrayOf<DaxMicAudioStream>()
  public var panadapterStreams = IdentifiedArrayOf<PanadapterStream>()
  public var remoteRxAudioStreams = IdentifiedArrayOf<RemoteRxAudioStream>()
  public var remoteTxAudioStreams = IdentifiedArrayOf<RemoteTxAudioStream>()
  public var waterfallStreams = IdentifiedArrayOf<WaterfallStream>()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func streamDistributor(_ vita: Vita) {
    

//    print("----->>>>> \(Thread.current.threadName)")

    // update the statistics
    
    // NOTE: StreamStatistics is @Observable therefore requires async updating on the MainActor
    Task {
      await MainActor.run { StreamStatistics.shared.stats[id: vita.classCode]?.packets += 1  }
    }
        
    switch vita.classCode {
    case .panadapter:
      if let object = panadapterStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
    case .waterfall:
      if let object = waterfallStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
    case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
      if let object = daxIqStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
    case .daxAudio, .daxAudioReducedBw:
      if let object = daxRxAudioStreams[id: vita.streamId] { object.streamProcessor(vita) }
      if let object = daxMicAudioStreams[id: vita.streamId]  { object.streamProcessor(vita) }
      if let object = remoteRxAudioStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
    case .meter:
      if meterStream == nil { meterStream = MeterStream(vita.streamId) }
      meterStream?.streamProcessor(vita)
      
    case .opus:
      if let object = remoteRxAudioStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
    default:
      // log the error
      log("StreamModel: unknown Vita class code: \(vita.classCode.description()) Stream Id = \(vita.streamId.hex)", .error, #function, #file, #line)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Stream parse methods

  public func parse(_ statusMessage: String, _ connectionHandle: UInt32?, _ testMode: Bool) {
    enum Property: String {
      case daxIq            = "dax_iq"
      case daxMic           = "dax_mic"
      case daxRx            = "dax_rx"
      case daxTx            = "dax_tx"
      case remoteRx         = "remote_audio_rx"
      case remoteTx         = "remote_audio_tx"
    }
    
    let properties = statusMessage.keyValuesArray()
    
    // is the 1st KeyValue a StreamId?
    if let id = properties[0].key.streamId {
      
      // is it a removal?
      if statusMessage.contains(kRemoved) {
        // YES
        removeStream(having: id)
        
      } else {
        // NO is it for me?
        if isForThisClient(properties, connectionHandle, testMode) {
          // YES
          guard properties.count > 1 else {
            log("StreamModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
            return
          }
          guard let token = Property(rawValue: properties[1].value) else {
            // log it and ignore the Key
            log("StreamModel: unknown Stream type: \(properties[1].value)", .warning, #function, #file, #line)
            return
          }
          switch token {
            
          case .daxIq:      daxIqStreamStatus(properties)
          case .daxMic:     daxMicAudioStreamStatus(properties)
          case .daxRx:      daxRxAudioStreamStatus(properties)
          case .daxTx:      daxTxAudioStreamStatus(properties)
          case .remoteRx:   remoteRxAudioStreamStatus(properties)
          case .remoteTx:   remoteTxAudioStreamStatus(properties)
          }
        }
      }
    } else {
      log("StreamModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
    }
  }

  /// Unsubscribe from UDP streams
//  public func unSubscribeFromStreams() {
//    log("StreamModel: stream subscription CANCELLED", .debug, #function, #file, #line)
//    _streamSubscription?.cancel()
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Status methods

  /// Evaluate a Status messaage
  /// - Parameters:
  ///   - properties: properties in KeyValuesArray form
  private func daxIqStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxIqStreams[id: id] == nil { daxIqStreams.append( DaxIqStream(id) ) }
      // parse the properties
      daxIqStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  private func daxMicAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxMicAudioStreams[id: id] == nil { daxMicAudioStreams.append( DaxMicAudioStream(id) ) }
      // parse the properties
      daxMicAudioStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  private func daxTxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxTxAudioStreams[id: id] == nil { daxTxAudioStreams.append( DaxTxAudioStream(id) ) }
      // parse the properties
      daxTxAudioStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  private func daxRxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxRxAudioStreams[id: id] == nil { daxRxAudioStreams.append( DaxRxAudioStream(id) ) }
      // parse the properties
      daxRxAudioStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  private func remoteRxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteRxAudioStreams[id: id] == nil { remoteRxAudioStreams.append( RemoteRxAudioStream(id) ) }
      // parse the properties
      remoteRxAudioStreams[id: id]!.parse( Array(properties.dropFirst(2)) )
    }
  }

  private func remoteTxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteTxAudioStreams[id: id] == nil { remoteTxAudioStreams.append( RemoteTxAudioStream(id) ) }
      // parse the properties
      remoteTxAudioStreams[id: id]!.parse( Array(properties.dropFirst(2)) )
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Removal methods

  private func removeStream(having id: UInt32) {
    if daxIqStreams[id: id] != nil {
      daxIqStreams.remove(id: id)
      log("StreamModel: DaxIqStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if daxMicAudioStreams[id: id] != nil {
      daxMicAudioStreams.remove(id: id)
      log("StreamModel: DaxMicAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if daxRxAudioStreams[id: id] != nil {
      daxRxAudioStreams.remove(id: id)
      log("StreamModel: DaxRxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)

    } else if daxTxAudioStreams[id: id] != nil {
      daxTxAudioStreams.remove(id: id)
      log("StreamModel: DaxTxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if remoteRxAudioStreams[id: id] != nil {
      remoteRxAudioStreams.remove(id: id)
      log("StreamModel: RemoteRxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if remoteTxAudioStreams[id: id] != nil {
      remoteTxAudioStreams.remove(id: id)
      log("StreamModel: RemoteTxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Helper methods

  /// Determine if status is for this client
  /// - Parameters:
  ///   - properties:     a KeyValuesArray
  ///   - clientHandle:   the handle of ???
  /// - Returns:          true if a mtch
  private func isForThisClient(_ properties: KeyValuesArray, _ connectionHandle: UInt32?, _ testMode: Bool) -> Bool {
    var clientHandle : UInt32 = 0
    
    guard testMode == false else { return true }
    
    if let connectionHandle {
      // find the handle property
      for property in properties.dropFirst(2) where property.key == "client_handle" {
        clientHandle = property.value.handle ?? 0
      }
      return clientHandle == connectionHandle
    }
    return false
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Udp subscription methods

  // Process the AsyncStream of UDP status changes
  private func subscribeToUdpStatus() {
    Task(priority: .high) {
      log("StreamModel: UdpStatus subscription STARTED", .debug, #function, #file, #line)
      for await status in Udp.shared.statusStream {
        udpStatus(status)
      }
      log("StreamModel: UdpStatus subscription STOPPED", .debug, #function, #file, #line)
    }
  }

  private func udpStatus(_ status: UdpStatus) {
    switch status.statusType {
      
    case .didUnBind:
      log("StreamModel: Udp unbound from port, \(status.receivePort)", .debug, #function, #file, #line)
    case .failedToBind:
      log("StreamModel: Udp failed to bind, " + (status.error?.localizedDescription ?? "unknown error"), .warning, #function, #file, #line)
    case .readError:
      log("StreamModel: Udp read error, " + (status.error?.localizedDescription ?? "unknown error"), .warning, #function, #file, #line)
    }
  }

  /*
   "stream set 0x" + _streamId.ToString("X") + " daxiq_rate=" + _sampleRate
   "stream remove 0x" + _streamId.ToString("X")
   "stream set 0x" + _txStreamID.ToString("X") + " tx=" + Convert.ToByte(_transmit)
   "stream create type=dax_rx dax_channel=" + channel
   "stream create type=dax_mic"
   "stream create type=dax_tx"
   "stream create type=dax_iq daxiq_channel=" + channel
   "stream create type=remote_audio_rx"
   "stream create type=remote_audio_rx compression=opus"
   "stream create type=remote_audio_rx compression=none"
   "stream create type=remote_audio_tx"
   */
}
