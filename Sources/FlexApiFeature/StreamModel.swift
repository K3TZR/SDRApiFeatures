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

public class StreamStatus: ObservableObject, Identifiable {
  @Published public var type: Vita.PacketClassCodes
  @Published public var packets = 0
  @Published public var errors = 0
  
  public var id: Vita.PacketClassCodes { type }
  
  public init(_ type: Vita.PacketClassCodes)
  {
    self.type = type
  }
}

final public class StreamStatistics: ObservableObject {
  public static var shared = StreamStatistics()
  private init() {}

    // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var streamStatus: IdentifiedArrayOf<StreamStatus> = [
    StreamStatus(Vita.PacketClassCodes.daxAudio),
    StreamStatus(Vita.PacketClassCodes.daxAudioReducedBw),
    StreamStatus(Vita.PacketClassCodes.daxIq24),
    StreamStatus(Vita.PacketClassCodes.daxIq48),
    StreamStatus(Vita.PacketClassCodes.daxIq96),
    StreamStatus(Vita.PacketClassCodes.daxIq192),
    StreamStatus(Vita.PacketClassCodes.meter),
    StreamStatus(Vita.PacketClassCodes.opus),
    StreamStatus(Vita.PacketClassCodes.panadapter),
    StreamStatus(Vita.PacketClassCodes.waterfall),
  ]
}

@Observable
final public class StreamModel {
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
  // MARK: - Private properties
  
  private var _streamSubscription: Task<(), Never>? = nil
  private var _streamStatistics = StreamStatistics.shared
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public static var shared = StreamModel()
  private init() {
    
    _streamSubscription = Task(priority: .high) {
      
      log("StreamModel: UDP stream subscription STARTED", .debug, #function, #file, #line)
      for await vita in Udp.shared.inboundStreams {
        // update the statistics
        _streamStatistics.streamStatus[id: vita.classCode]?.packets += 1
        
        switch vita.classCode {
        case .panadapter:
          if let object = panadapterStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
        case .waterfall:
          if let object = waterfallStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
        case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
          if let object = daxIqStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
        case .daxAudio, .daxAudioReducedBw:
          if let stream = daxRxAudioStreams[id: vita.streamId] {
            stream.delegate?.daxAudioOutputHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxAudioReducedBw)
          }
          if let stream = daxMicAudioStreams[id: vita.streamId] {
            stream.delegate?.daxAudioOutputHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxAudioReducedBw)
          }
          if let object = remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
          //        case .daxReducedBw:
          //          if let stream = await ApiModel.shared.daxRxAudioStreams[id: vita.streamId] {
          //            stream.delegate?.daxAudioHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxReducedBw)
          //          }
          //
          //          if let stream = await ApiModel.shared.daxMicAudioStreams[id: vita.streamId] {
          //            stream.delegate?.daxAudioHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxReducedBw)
          //          }
          
        case .meter:
          await Meter.vitaProcessor(vita)
          
        case .opus:
          if let object = remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
        default:
          // log the error
          log("StreamModel: unknown Vita class code: \(vita.classCode.description()) Stream Id = \(vita.streamId.hex)", .error, #function, #file, #line)
        }
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Unsubscribe from UDP streams
  public func unSubscribeToStreams() {
    log("StreamModel: stream subscription CANCELLED", .debug, #function, #file, #line)
    _streamSubscription?.cancel()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Stream methods
  
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
            log("ApiModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
            return
          }
          guard let token = Property(rawValue: properties[1].value) else {
            // log it and ignore the Key
            log("ApiModel: unknown Stream type: \(properties[1].value)", .warning, #function, #file, #line)
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

  /// Send a Remove Stream command to the radio
  /// - Parameter having: a StreamId
  @MainActor public func sendRemoveStreams(_ ids: [UInt32?]) {
    for id in ids where id != nil {
      ApiModel.shared.sendCommand("stream remove \(id!.hex)")
    }
  }

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
      log("ApiModel: DaxIqStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if daxMicAudioStreams[id: id] != nil {
      daxMicAudioStreams.remove(id: id)
      log("ApiModel: DaxMicAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if daxRxAudioStreams[id: id] != nil {
      daxRxAudioStreams.remove(id: id)
      log("ApiModel: DaxRxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)

    } else if daxTxAudioStreams[id: id] != nil {
      daxTxAudioStreams.remove(id: id)
      log("ApiModel: DaxTxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if remoteRxAudioStreams[id: id] != nil {
      remoteRxAudioStreams.remove(id: id)
      log("ApiModel: RemoteRxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
    }
    else if remoteTxAudioStreams[id: id] != nil {
      remoteTxAudioStreams.remove(id: id)
      log("ApiModel: RemoteTxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
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

//@Observable
//public class VitaStatus: Identifiable {
//  public var type: Vita.PacketClassCodes
//  public var packets = 0
//  public var errors = 0
//
//  public var id: Vita.PacketClassCodes { type }
//
//  public init(_ type: Vita.PacketClassCodes)
//  {
//    self.type = type
//  }
//}
//}
