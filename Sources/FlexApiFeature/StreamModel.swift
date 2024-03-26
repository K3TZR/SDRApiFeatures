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

@Observable
public class VitaStatus: Identifiable {
  public var type: Vita.PacketClassCodes
  public var packets = 0
  public var errors = 0
  
  public var id: Vita.PacketClassCodes { type }
  
  public init(_ type: Vita.PacketClassCodes)
  {
    self.type = type
  }
}

final public class StreamModel {

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var streamStatus: IdentifiedArrayOf<VitaStatus> = [
    VitaStatus(Vita.PacketClassCodes.daxAudio),
    VitaStatus(Vita.PacketClassCodes.daxAudioReducedBw),
    VitaStatus(Vita.PacketClassCodes.daxIq24),
    VitaStatus(Vita.PacketClassCodes.daxIq48),
    VitaStatus(Vita.PacketClassCodes.daxIq96),
    VitaStatus(Vita.PacketClassCodes.daxIq192),
    VitaStatus(Vita.PacketClassCodes.meter),
    VitaStatus(Vita.PacketClassCodes.opus),
    VitaStatus(Vita.PacketClassCodes.panadapter),
    VitaStatus(Vita.PacketClassCodes.waterfall),
  ]

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _streamSubscription: Task<(), Never>? = nil

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
//  public static var shared = StreamModel()
  public init() {
    
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
