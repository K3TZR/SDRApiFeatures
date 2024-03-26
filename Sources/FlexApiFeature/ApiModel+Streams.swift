//
//  File.swift
//  
//
//  Created by Douglas Adams on 10/22/23.
//

import Foundation

import SharedFeature
import UdpFeature
import VitaFeature

extension ApiModel {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Stream methods
  
  public func parse(_ statusMessage: String) {
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
      
      Task {
        await MainActor.run {
          // is it a removal?
          if statusMessage.contains(kRemoved) {
            // YES
            removeStream(having: id)
            
          } else {
            // NO is it for me?
            if isForThisClient(properties) {
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
        }
      }
    } else {
      log("ApiModel: invalid Stream message: \(statusMessage)", .warning, #function, #file, #line)
    }
  }

  /// Send a Remove Stream command to the radio
  /// - Parameter having: a StreamId
  @MainActor public func sendRemoveStreams(_ ids: [UInt32?]) {
    for id in ids where id != nil {
      sendCommand("stream remove \(id!.hex)")
    }
  }
  
  public func meterBy(shortName: Meter.ShortName, slice: Slice? = nil) -> Meter? {
    
    if slice == nil {
      for meter in meters where meter.name == shortName.rawValue {
        return meter
      }
    } else {
      for meter in meters where slice!.id == UInt32(meter.group) && meter.name == shortName.rawValue {
        return meter
      }
    }
    return nil
  }
  

  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Subscription methods

  /// Subscribe to UDP streams
//  func subscribeToStreams()  {
//    _streamSubscription = Task(priority: .high) {
//      
//      log("ApiModel: UDP stream subscription STARTED", .debug, #function, #file, #line)
//      for await vita in Udp.shared.inboundStreams {
//        Task {
//          await MainActor.run { self.streamStatus[id: vita.classCode]?.packets += 1 }
//        }
//        switch vita.classCode {
//        case .panadapter:
//          if let object = self.panadapters[id: vita.streamId] { object.vitaProcessor(vita) }
//          
//        case .waterfall:
//          if let object = self.waterfalls[id: vita.streamId] { object.vitaProcessor(vita) }
//          
//        case .daxIq24, .daxIq48, .daxIq96, .daxIq192:
//          if let object = self.daxIqStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//          
//        case .daxAudio:
//          if let object = self.daxRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita)}
//          if let object = self.daxMicAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//          if let object = self.remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//          
//        case .daxReducedBw:
//          if let object = self.daxRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//          if let object = self.daxMicAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//          
//        case .meter:
//          if meterStream == nil { meterStream = MeterStream(vita.streamId) }
//          meterStream!.vitaProcessor(vita)
//
//        case .opus:
//          if let object = remoteRxAudioStreams[id: vita.streamId] { object.vitaProcessor(vita) }
//          
//        default:
//          // log the error
//          log("ApiModel: unknown Vita class code: \(vita.classCode.description()) Stream Id = \(vita.streamId.hex)", .error, #function, #file, #line)
//        }
//      }
//      log("ApiModel: UDP stream  subscription STOPPED", .debug, #function, #file, #line)
//    }
//  }
//  
//  /// Unsubscribe from UDP streams
//  private func unSubscribeToStreams() {
//    log("ApiModel: stream subscription CANCELLED", .debug, #function, #file, #line)
//    _streamSubscription?.cancel()
//  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Stream Status methods

  /// Evaluate a Status messaage
  /// - Parameters:
  ///   - properties: properties in KeyValuesArray form
  @MainActor private func daxIqStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxIqStreams[id: id] == nil { daxIqStreams.append( DaxIqStream(id) ) }
      // parse the properties
      daxIqStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  @MainActor private func daxMicAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxMicAudioStreams[id: id] == nil { daxMicAudioStreams.append( DaxMicAudioStream(id) ) }
      // parse the properties
      daxMicAudioStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  @MainActor private func daxTxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxTxAudioStreams[id: id] == nil { daxTxAudioStreams.append( DaxTxAudioStream(id) ) }
      // parse the properties
      daxTxAudioStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  @MainActor private func daxRxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if daxRxAudioStreams[id: id] == nil { daxRxAudioStreams.append( DaxRxAudioStream(id) ) }
      // parse the properties
      daxRxAudioStreams[id: id]!.parse( Array(properties.dropFirst(1)) )
    }
  }

  @MainActor private func remoteRxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteRxAudioStreams[id: id] == nil { remoteRxAudioStreams.append( RemoteRxAudioStream(id, self) ) }
      // parse the properties
      remoteRxAudioStreams[id: id]!.parse( Array(properties.dropFirst(2)) )
    }
  }

  @MainActor private func remoteTxAudioStreamStatus(_ properties: KeyValuesArray) {
    // get the id
    if let id = properties[0].key.streamId {
      // add it if not already present
      if remoteTxAudioStreams[id: id] == nil { remoteTxAudioStreams.append( RemoteTxAudioStream(id) ) }
      // parse the properties
      remoteTxAudioStreams[id: id]!.parse( Array(properties.dropFirst(2)) )
    }
  }
  
  @MainActor public func meterStatus(_ properties: KeyValuesArray, _ inUse: Bool) {
    // get the id
    if let id = UInt32(properties[0].key.components(separatedBy: ".")[0], radix: 10) {
      // is it in use?
      if inUse {
        // YES, add it if not already present
        if meters[id: id] == nil { meters.append( Meter(id, self) ) }
        // parse the properties
        meters[id: id]!.parse(properties )
        
      } else {
        // NO, remove it
        meters.remove(id: id)
        log("Meter \(id): REMOVED", .debug, #function, #file, #line)
      }
    }
  }
  
  /// Process the Vita struct containing Meter data
  /// - Parameters:
  ///   - vita:        a Vita struct
//  private func meterVitaProcessor(_ vita: Vita) {
//    let kDbDbmDbfsSwrDenom: Float = 128.0   // denominator for Db, Dbm, Dbfs, Swr
//    let kDegDenom: Float = 64.0             // denominator for Degc, Degf
//    
//    var meterIds = [UInt32]()
//    
//    //    if isStreaming == false {
//    //      isStreaming = true
//    //      streamId = vita.streamId
//    //      // log the start of the stream
//    //      log("Meter \(vita.streamId.hex) stream: STARTED", .info, #function, #file, #line)
//    //    }
//    
//    // NOTE:  there is a bug in the Radio (as of v2.2.8) that sends
//    //        multiple copies of meters, this code ignores the duplicates
//    
//    vita.payloadData.withUnsafeBytes { payloadPtr in
//      // four bytes per Meter
//      let numberOfMeters = Int(vita.payloadSize / 4)
//      
//      // pointer to the first Meter number / Meter value pair
//      let ptr16 = payloadPtr.bindMemory(to: UInt16.self)
//      
//      // for each meter in the Meters packet
//      for i in 0..<numberOfMeters {
//        // get the Meter id and the Meter value
//        let id: UInt32 = UInt32(CFSwapInt16BigToHost(ptr16[2 * i]))
//        let value: UInt16 = CFSwapInt16BigToHost(ptr16[(2 * i) + 1])
//        
//        // is this a duplicate?
//        if !meterIds.contains(id) {
//          // NO, add it to the list
//          meterIds.append(id)
//          
//          // find the meter (if present) & update it
//          if let meter = meters[id: id] {
//            //          meter.streamHandler( value)
//            let newValue = Int16(bitPattern: value)
//            let previousValue = meter.value
//            
//            // check for unknown Units
//            guard let token = Units(rawValue: meter.units) else {
//              //      // log it and ignore it
//              //      log("Meter \(desc) \(description) \(group) \(name) \(source): unknown units - \(units))", .warning, #function, #file, #line)
//              return
//            }
//            var adjNewValue: Float = 0.0
//            switch token {
//              
//            case .db, .dbm, .dbfs, .swr:        adjNewValue = Float(exactly: newValue)! / kDbDbmDbfsSwrDenom
//            case .volts, .amps:                 adjNewValue = Float(exactly: newValue)! / 256.0
//            case .degc, .degf:                  adjNewValue = Float(exactly: newValue)! / kDegDenom
//            case .rpm, .watts, .percent, .none: adjNewValue = Float(exactly: newValue)!
//            }
//            // did it change?
//            if adjNewValue != previousValue {
//              let value = adjNewValue
//              Task {
//                await MainActor.run { meters[id: id]?.value = value }
//              }
//            }
//          }
//        }
//      }
//    }
//  }

  
  
  
  
  
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
  private func isForThisClient(_ properties: KeyValuesArray) -> Bool {
    var clientHandle : UInt32 = 0
    
    if let connectionHandle = connectionHandle {
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
