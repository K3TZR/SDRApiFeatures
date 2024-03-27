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

public class StreamStatus: Identifiable {
  public var type: Vita.PacketClassCodes
  public var packets = 0
  public var errors = 0
  
  public var id: Vita.PacketClassCodes { type }
  
  public init(_ type: Vita.PacketClassCodes)
  {
    self.type = type
  }
}

@Observable
final public class StreamModel {

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

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _streamSubscription: Task<(), Never>? = nil

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public static var shared = StreamModel()
  private init() {
    
    _streamSubscription = Task(priority: .high) {
      
      log("ApiModel: UDP stream subscription STARTED", .debug, #function, #file, #line)
      for await vita in Udp.shared.inboundStreams {
        self.streamStatus[id: vita.classCode]?.packets += 1 
        
        switch vita.classCode {
        case .panadapter:
          if let object = await ApiModel.shared.panadapters[id: vita.streamId] { await object.vitaProcessor(vita) }
          
        case .waterfall:
          if let object = await ApiModel.shared.waterfalls[id: vita.streamId] { await object.vitaProcessor(vita) }
          
        case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
          if let object = await ApiModel.shared.daxIqStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
        case .daxAudio, .daxAudioReducedBw:
          if let stream = await ApiModel.shared.daxRxAudioStreams[id: vita.streamId] {
            stream.delegate?.daxAudioHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxAudioReducedBw)
          }
          if let stream = await ApiModel.shared.daxMicAudioStreams[id: vita.streamId] {
            stream.delegate?.daxAudioHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxAudioReducedBw)
          }
          if let object = await ApiModel.shared.remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
//        case .daxReducedBw:
//          if let stream = await ApiModel.shared.daxRxAudioStreams[id: vita.streamId] {
//            stream.delegate?.daxAudioHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxReducedBw)
//          }
//
//          if let stream = await ApiModel.shared.daxMicAudioStreams[id: vita.streamId] {
//            stream.delegate?.daxAudioHandler( payload: vita.payloadData, reducedBW: vita.classCode == .daxReducedBw)
//          }

        case .meter:
          //          if await meterStream == nil { meterStream = MeterStream(vita.streamId) }
          //          await meterStream!.vitaProcessor(vita)
          break
          
        case .opus:
          if let object = await ApiModel.shared.remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
          
        default:
          // log the error
          log("ApiModel: unknown Vita class code: \(vita.classCode.description()) Stream Id = \(vita.streamId.hex)", .error, #function, #file, #line)
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Unsubscribe from UDP streams
  public func unSubscribeToStreams() {
    log("ApiModel: stream subscription CANCELLED", .debug, #function, #file, #line)
    _streamSubscription?.cancel()
  }
}
