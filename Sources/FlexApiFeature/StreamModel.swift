//
//  StreamModel.swift
//
//
//  Created by Douglas Adams on 3/22/24.
//

import Foundation

import SharedFeature
import UdpFeature
import VitaFeature

//final public class StreamModel: StreamsProcessor {
//  // ----------------------------------------------------------------------------
//  // MARK: - Singleton
//  
//  public static var shared = StreamModel()
//  private init() {}
//  
//  // ----------------------------------------------------------------------------
//  // MARK: - Public methods
//
//    public func streamsProcessor(_ vita: Vita) async {
//    
//    //    log("ApiModel: UDP stream subscription STARTED", .debug, #function, #file, #line)
//    //    for await vita in Udp.shared.inboundStreams {
//    //      Task {
//    //        await MainActor.run { self.streamStatus[id: vita.classCode]?.packets += 1 }
//    //      }
//    switch vita.classCode {
//    case .panadapter:
//      if let object = await ApiModel.shared.panadapters[id: vita.streamId] { await object.vitaProcessor(vita) }
//      
//    case .waterfall:
//      if let object = await ApiModel.shared.waterfalls[id: vita.streamId] { await object.vitaProcessor(vita) }
//      
//    case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
//      if let object = await ApiModel.shared.daxIqStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//      
//    case .daxAudio:
//      if let object = await ApiModel.shared.daxRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita)}
//      if let object = await ApiModel.shared.daxMicAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//      if let object = await ApiModel.shared.remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//      
//    case .daxReducedBw:
//      if let object = await ApiModel.shared.daxRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//      if let object = await ApiModel.shared.daxMicAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//      
//    case .meter:
//      //          if await meterStream == nil { meterStream = MeterStream(vita.streamId) }
//      //          await meterStream!.vitaProcessor(vita)
//      break
//      
//    case .opus:
//      if let object = await ApiModel.shared.remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//      
//    default:
//      // log the error
//      SharedFeature.log("ApiModel: unknown Vita class code: \(vita.classCode.description()) Stream Id = \(vita.streamId.hex)", .error, #function, #file, #line)
//    }
//  }
//}

/// Unsubscribe from UDP streams
//  private func unSubscribeToStreams() {
//    log("ApiModel: stream subscription CANCELLED", .debug, #function, #file, #line)
//    streamSubscription?.cancel()
//  }
//}
