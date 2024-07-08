//
//  StreamModel.swift
//
//
//  Created by Douglas Adams on 3/22/24.
//

import IdentifiedCollections
import Foundation

import AudioFeature
import SharedFeature
import VitaFeature


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
//  @Published public var packets = 0
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

//@Observable
//@MainActor
final public actor StreamModel: StreamProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton

//  public static var shared = StreamModel()
//  private init() {}
  public init(_ objectModel: ObjectModel) {
    _objectModel = objectModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // single streams
//  public var daxMicAudioStream: DaxMicAudioStream?
//  public var daxTxAudioStream: DaxTxAudioStream?
  public var meterStream: MeterStream?
//  public var remoteRxAudioStream: RemoteRxAudioStream?
//  public var remoteTxAudioStream: RemoteTxAudioStream?
//
//  // collection streams
//  public var daxIqStreams = IdentifiedArrayOf<DaxIqStream>()
//  public var daxRxAudioStreams = IdentifiedArrayOf<DaxRxAudioStream>()
//  public var panadapterStreams = IdentifiedArrayOf<PanadapterStream>()
//  public var waterfallStreams = IdentifiedArrayOf<WaterfallStream>()
  
  public var rxAudioOutput: RxAudioPlayer?
  public var daxAudioOutputs: [DaxAudioPlayer?] = Array(repeating: nil, count: 5)

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _objectModel: ObjectModel
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func streamProcessor(_ vita: Vita) {
    // NOTE: StreamStatistics is @Observable therefore requires async updating on the MainActor
//    Task {
//      // update the statistics
//      await MainActor.run { StreamStatistics.shared.stats[id: vita.classCode]?.packets += 1  }
//    }
    // pass Stream data to the appropriate Object
    switch vita.classCode {
//    case .panadapter:
//      if let object = panadapterStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
//    case .waterfall:
//      if let object = await waterfallStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
//    case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
//      if let object = daxIqStreams[id: vita.streamId] { object.streamProcessor(vita) }
      
    case .daxAudio, .daxAudioReducedBw:
      for output in daxAudioOutputs where output?.streamId == vita.streamId {
        output?.audioProcessor(vita)
      }
//      if let object = daxRxAudioStreams[id: vita.streamId] {
//        object.streamProcessor(vita)
//      } else if daxMicAudioStream?.id == vita.streamId {
//        daxMicAudioStream?.streamProcessor(vita)
//      } else {
//        remoteRxAudioStream?.streamProcessor(vita)
//      }
      
    case .meter:
      if meterStream == nil { meterStream = MeterStream(vita.streamId, _objectModel) }
      meterStream?.streamProcessor(vita)
      
    case .opus:
//      _objectModel.rxAudioOutput?.audioProcessor(vita)
      print("count ", vita.payloadData.count)
      
    default:
//      log("StreamModel: unknown Vita class code: \(vita.classCode.description()) Stream Id = \(vita.streamId.hex)", .error, #function, #file, #line)
      break
    }
    //    }
  }
  
//  public func add(_ type: StreamType, _ id: UInt32) {
//    switch type {
//    case .panadapter:     panadapterStreams[id: id] = PanadapterStream(id)
//    case .waterfall:      waterfallStreams[id: id] = WaterfallStream(id)
////    case .meter:          meterStream = MeterStream(id)
//    case .remoteRxAudioStream:    remoteRxAudioStream = RemoteRxAudioStream(id)
//    case .daxIqStream:
//      break
//    case .daxMicAudioStream:
//      break
//    case .daxRxAudioStream:
//      break
//    case .daxTxAudioStream:
//      break
//    case .remoteTxAudioStream:
//      break
//    }
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Stream parse methods

//  public func parse(_ statusMessage: String, _ connectionHandle: UInt32?, _ testMode: Bool) {
//    enum Property: String {
//      case daxIq            = "dax_iq"
//      case daxMic           = "dax_mic"
//      case daxRx            = "dax_rx"
//      case daxTx            = "dax_tx"
//      case remoteRx         = "remote_audio_rx"
//      case remoteTx         = "remote_audio_tx"
//    }
//    
//    let properties = statusMessage.keyValuesArray()
//    
//    // is the 1st KeyValue a StreamId?
//    if let id = properties[0].key.streamId {
//      
//      // is it a removal?
//      if statusMessage.contains(kRemoved) {
//        // YES
//        removeStream(having: id)
//        
//      } else {
//        // NO is it for me?
//        if isForThisClient(properties, connectionHandle, testMode) {
//          // YES
//          guard properties.count > 1 else {
//            log("StreamModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
//            return
//          }
//          guard let token = Property(rawValue: properties[1].value) else {
//            // log it and ignore the Key
//            log("StreamModel: unknown Stream type: \(properties[1].value)", .warning, #function, #file, #line)
//            return
//          }
//          switch token {
//            
//          case .daxIq:      daxIqStreamStatus(properties)
//          case .daxMic:     daxMicAudioStreamStatus(properties)
//          case .daxRx:      daxRxAudioStreamStatus(properties)
//          case .daxTx:      daxTxAudioStreamStatus(properties)
//          case .remoteRx:   remoteRxAudioStreamStatus(properties)
//          case .remoteTx:   remoteTxAudioStreamStatus(properties)
//          }
//        }
//      }
//    } else {
//      log("StreamModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
//    }
//  }

  
  // ----------------------------------------------------------------------------
  // MARK: Public Stream request/remove methods
  
//  public func requestStream(_ streamType: StreamType, daxChannel: Int = 0, isCompressed: Bool = false, replyTo callback: ReplyHandler? = nil)  {
//    switch streamType {
//    case .remoteRxAudioStream:  ApiModel.shared.sendTcp("stream create type=\(streamType.rawValue) compression=\(isCompressed ? "opus" : "none")", replyTo: callback)
//    case .remoteTxAudioStream:  ApiModel.shared.sendTcp("stream create type=\(streamType.rawValue)", replyTo: callback)
//    case .daxMicAudioStream:    ApiModel.shared.sendTcp("stream create type=\(streamType.rawValue)", replyTo: callback)
//    case .daxRxAudioStream:     ApiModel.shared.sendTcp("stream create type=\(streamType.rawValue) dax_channel=\(daxChannel)", replyTo: callback)
//    case .daxTxAudioStream:     ApiModel.shared.sendTcp("stream create type=\(streamType.rawValue)", replyTo: callback)
//    case .daxIqStream:          ApiModel.shared.sendTcp("stream create type=\(streamType.rawValue) dax_channel=\(daxChannel)", replyTo: callback)
//    default: return
//    }
//  }

  public func daxRxAudioStart(_ streamId: UInt32, _ channel: Int)  {
    daxAudioOutputs[channel] = DaxAudioPlayer(streamId)
    daxAudioOutputs[channel]?.start()
  }
  
  public func daxRxAudioStop(_ channel: Int)  {
    daxAudioOutputs[channel]?.stop()
    if let streamId = daxAudioOutputs[channel]?.streamId {
      Task { await MainActor.run {
        _objectModel.sendTcp("stream remove \(streamId.hex)")
      }}
    }
    daxAudioOutputs[channel] = nil
  }

  public func remoteRxAudioStart(_ streamId: UInt32)  {
    rxAudioOutput = RxAudioPlayer(streamId)
    rxAudioOutput?.start()
  }
  
  public func remoteRxAudioStop()  {
    rxAudioOutput?.stop()
    if let streamId = rxAudioOutput?.streamId {
      Task { await MainActor.run {
        _objectModel.sendTcp("stream remove \(streamId.hex)")
      }}
    }
    rxAudioOutput = nil
  }

//  public func remove(_ streamId: UInt32?)  {
//    if let streamId {
//      ApiModel.shared.sendTcp("stream remove \(streamId.hex)")
//    }
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Status methods

  /// Evaluate a Status messaage
  /// - Parameters:
  ///   - properties: properties in KeyValuesArray form
//  private func daxIqStreamStatus(_ properties: KeyValuesArray) {
//    // get the id
//    if let id = properties[0].key.streamId {
//      // add it if not already present
//      if daxIqStreams[id: id] == nil { daxIqStreams.append( DaxIqStream(id) ) }
//      // parse the properties
//      daxIqStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
//    }
//  }
//
//  private func daxMicAudioStreamStatus(_ properties: KeyValuesArray) {
//    // get the id
//    if let id = properties[0].key.streamId {
//      // add it if not already present
//      if daxMicAudioStream == nil { daxMicAudioStream = DaxMicAudioStream(id) }
//      // parse the properties
//      daxMicAudioStream?.parse( Array(properties.dropFirst(1)) )
//    }
//  }
//
//  private func daxRxAudioStreamStatus(_ properties: KeyValuesArray) {
//    // get the id
//    if let id = properties[0].key.streamId {
//      // add it if not already present
//      if daxRxAudioStreams[id: id] == nil { daxRxAudioStreams.append( DaxRxAudioStream(id) ) }
//      // parse the properties
//      daxRxAudioStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
//    }
//  }
//
//  private func daxTxAudioStreamStatus(_ properties: KeyValuesArray) {
//    // get the id
//    if let id = properties[0].key.streamId {
//      // add it if not already present
//      if daxTxAudioStream == nil { daxTxAudioStream = DaxTxAudioStream(id) }
//      // parse the properties
//      daxTxAudioStream?.parse( Array(properties.dropFirst(1)) )
//    }
//  }
//
//  private func remoteRxAudioStreamStatus(_ properties: KeyValuesArray) {
//    // get the id
//    if let id = properties[0].key.streamId {
//      // add it if not already present
//      if remoteRxAudioStream == nil { remoteRxAudioStream = RemoteRxAudioStream(id) }
//      // parse the properties
//      remoteRxAudioStream?.parse( Array(properties.dropFirst(2)) )
//    }
//  }
//
//  private func remoteTxAudioStreamStatus(_ properties: KeyValuesArray) {
//    // get the id
//    if let id = properties[0].key.streamId {
//      // add it if not already present
//      if remoteTxAudioStream == nil { remoteTxAudioStream = RemoteTxAudioStream(id)  }
//      // parse the properties
//      remoteTxAudioStream?.parse( Array(properties.dropFirst(2)) )
//    }
//  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Removal methods

//  private func removeStream(having id: UInt32) {
//    if daxIqStreams[id: id] != nil {
//      daxIqStreams.remove(id: id)
//      log("StreamModel: DaxIqStream \(id.hex): REMOVED", .debug, #function, #file, #line)
//    }
//    else if daxMicAudioStream?.id == id {
//      daxMicAudioStream = nil
//      log("StreamModel: DaxMicAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
//    }
//    else if daxRxAudioStreams[id: id] != nil {
//      daxRxAudioStreams.remove(id: id)
//      log("StreamModel: DaxRxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
//
//    } else if daxTxAudioStream?.id == id {
//      daxTxAudioStream = nil
//      log("StreamModel: DaxTxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
//    }
//    else if remoteRxAudioStream?.id == id {
//      remoteRxAudioStream = nil
//      log("StreamModel: RemoteRxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
//    }
//    else if remoteTxAudioStream?.id == id {
//      remoteTxAudioStream = nil
//      log("StreamModel: RemoteTxAudioStream \(id.hex): REMOVED", .debug, #function, #file, #line)
//    }
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Helper methods

  /// Determine if status is for this client
  /// - Parameters:
  ///   - properties:     a KeyValuesArray
  ///   - clientHandle:   the handle of ???
  /// - Returns:          true if a mtch
//  private func isForThisClient(_ properties: KeyValuesArray, _ connectionHandle: UInt32?, _ testMode: Bool) -> Bool {
//    var clientHandle : UInt32 = 0
//    
//    guard testMode == false else { return true }
//    
//    if let connectionHandle {
//      // find the handle property
//      for property in properties.dropFirst(2) where property.key == "client_handle" {
//        clientHandle = property.value.handle ?? 0
//      }
//      return clientHandle == connectionHandle
//    }
//    return false
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Udp subscription methods

  // Process the AsyncStream of UDP status changes
//  private func subscribeToUdpStatus() {
//    Task(priority: .high) {
//      log("StreamModel: UdpStatus subscription STARTED", .debug, #function, #file, #line)
//      for await status in Udp.shared.statusStream {
//        udpStatus(status)
//      }
//      log("StreamModel: UdpStatus subscription STOPPED", .debug, #function, #file, #line)
//    }
//  }

//  private func udpStatus(_ status: UdpStatus) {
//    switch status.statusType {
//      
//    case .didUnBind:
//      log("StreamModel: Udp unbound from port, \(status.receivePort)", .debug, #function, #file, #line)
//    case .failedToBind:
//      log("StreamModel: Udp failed to bind, " + (status.error?.localizedDescription ?? "unknown error"), .warning, #function, #file, #line)
//    case .readError:
//      log("StreamModel: Udp read error, " + (status.error?.localizedDescription ?? "unknown error"), .warning, #function, #file, #line)
//    }
//  }

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
