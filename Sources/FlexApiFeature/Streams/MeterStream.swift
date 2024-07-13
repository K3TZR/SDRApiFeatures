//
//  MeterStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 1/11/24.
//

import Foundation

import SharedFeature
import VitaFeature


// MeterStream Class implementation
//      creates an MeterStream instance to be used by a Client to support the
//      processing of a UDP stream of Meter data from the Radio to the client. A MeterStream
//      is added by the first incoming TCP Meter message.
@Observable
public final class MeterStream: Identifiable, StreamProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ objectModel: ObjectModel) {
    self.id = id
    _objectModel = objectModel
    apiLog.debug("MeterStream \(id.hex) ADDED")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _objectModel: ObjectModel

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Process the Vita struct containing Meter data
  /// - Parameters:
  ///   - vita:        a Vita struct
  public func streamProcessor(_ vita: Vita) {
    let kDbDbmDbfsSwrDenom: Float = 128.0   // denominator for Db, Dbm, Dbfs, Swr
    let kDegDenom: Float = 64.0             // denominator for Degc, Degf
    
    var meterIds = [UInt32]()
    
    //    if isStreaming == false {
    //      isStreaming = true
    //      streamId = vita.streamId
    //      // log the start of the stream
    //      log("Meter \(vita.streamId.hex) stream: STARTED", .info, #function, #file, #line)
    //    }
    
    // NOTE:  there is a bug in the Radio (as of v2.2.8) that sends
    //        multiple copies of meters, this code ignores the duplicates
    
    vita.payloadData.withUnsafeBytes { payloadPtr in
      // four bytes per Meter
      let numberOfMeters = Int(vita.payloadSize / 4)
      
      // pointer to the first Meter number / Meter value pair
      let ptr16 = payloadPtr.bindMemory(to: UInt16.self)
      
      // for each meter in the Meters packet
      for i in 0..<numberOfMeters {
        // get the Meter id and the Meter value
        let id: UInt32 = UInt32(CFSwapInt16BigToHost(ptr16[2 * i]))
        let value: UInt16 = CFSwapInt16BigToHost(ptr16[(2 * i) + 1])
        
        // is this a duplicate?
        if !meterIds.contains(id) {
          // NO, add it to the list
          meterIds.append(id)
          
          // find the meter (if present) & update it
          // NOTE: ObjectModel is @MainActor therefore it's methods and properties must be accessed asynchronously
          Task {
            if let meter = await _objectModel.meters[id: id] {
              //          meter.streamHandler( value)
              let newValue = Int16(bitPattern: value)
              let previousValue = await meter.value
              
              // check for unknown Units
              guard let token = await MeterUnits(rawValue: meter.units) else {
                //      // log it and ignore it
                //      log("Meter \(desc) \(description) \(group) \(name) \(source): unknown units - \(units))", .warning, #function, #file, #line)
                return
              }
              var adjNewValue: Float = 0.0
              switch token {
                
              case .db, .dbm, .dbfs, .swr:        adjNewValue = Float(exactly: newValue)! / kDbDbmDbfsSwrDenom
              case .volts, .amps:                 adjNewValue = Float(exactly: newValue)! / 256.0
              case .degc, .degf:                  adjNewValue = Float(exactly: newValue)! / kDegDenom
              case .rpm, .watts, .percent, .none: adjNewValue = Float(exactly: newValue)!
              }
              // did it change?
              if adjNewValue != previousValue {
                let value = adjNewValue
                await _objectModel.meters[id: id]?.setValue(value)
              }
            }
          }
        }
      }
    }
  }
}

