//
//  Meter.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 6/2/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

import SharedFeature
import VitaFeature

@MainActor
//@Observable
public final class Meter: ObservableObject, Identifiable, Equatable {
  public nonisolated static func == (lhs: Meter, rhs: Meter) -> Bool {
    lhs.id == rhs.id
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ apiModel: ApiModel) {
    self.id = id
    _apiModel = apiModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var initialized: Bool = false
  
  public var desc: String = ""
  public var fps: Int = 0
  public var high: Float = 0
  public var low: Float = 0
  public var group: String = ""
  public var name: String = ""
  public var peak: Float = 0
  public var source: String = ""
  public var units: String = ""
  @Published public var value: Float = 0
  
  public static var streamId: UInt32?
  public static var isStreaming = false
  
  public enum Source: String {
    case codec      = "cod"
    case tx
    case slice      = "slc"
    case radio      = "rad"
    case amplifier  = "amp"
  }
  public enum ShortName: String, CaseIterable {
    case codecOutput            = "codec"
    case hwAlc                  = "hwalc"
    case microphoneAverage      = "mic"
    case microphoneOutput       = "sc_mic"
    case microphonePeak         = "micpeak"
    case postClipper            = "comppeak"
    case postFilter1            = "sc_filt_1"
    case postFilter2            = "sc_filt_2"
    case postGain               = "gain"
    case postRamp               = "aframp"
    case postSoftwareAlc        = "alc"
    case powerForward           = "fwdpwr"
    case powerReflected         = "refpwr"
    case preRamp                = "b4ramp"
    case preWaveAgc             = "pre_wave_agc"
    case preWaveShim            = "pre_wave"
    case signal24Khz            = "24khz"
    case signalPassband         = "level"
    case signalPostNrAnf        = "nr/anf"
    case signalPostAgc          = "agc+"
    case swr                    = "swr"
    case temperaturePa          = "patemp"
    case voltageAfterFuse       = "+13.8b"
    case voltageBeforeFuse      = "+13.8a"
  }
  
  public enum Property: String {
    case desc
    case fps
    case high       = "hi"
    case low
    case name       = "nam"
    case group      = "num"
    case source     = "src"
    case units      = "unit"
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _apiModel: ApiModel

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse Meter key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <n.key=value>
    for property in properties {
      // separate the Meter Number from the Key
      let numberAndKey = property.key.components(separatedBy: ".")
      
      // get the Key
      let key = numberAndKey[1]
      
      // check for unknown Keys
      guard let token = Meter.Property(rawValue: key) else {
        // unknown, log it and ignore the Key
        log("Meter \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known Keys, in alphabetical order
      switch token {
        
      case .desc:     desc = property.value
      case .fps:      fps = property.value.iValue
      case .high:     high = property.value.fValue
      case .low:      low = property.value.fValue
      case .name:     name = property.value.lowercased()
      case .group:    group = property.value
      case .source:   source = property.value.lowercased()
      case .units:    units = property.value.lowercased()
      }
    }
    // is it initialized?
    if initialized == false && group != "" && units != "" {
      //NO, it is now
      initialized = true
      log("Meter \(id): ADDED, name = \(name), source = \(source), group = \(group)", .debug, #function, #file, #line)
    }
  }
  
  public func setValue(_ value: Float) {
    self.value = value
  }
  
  /// Process the Vita struct containing Meter data
  /// - Parameters:
  ///   - vita:        a Vita struct
  public class func vitaProcessor(_ vita: Vita) {
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
          Task {
            if let meter = ApiModel.shared.meters[id: id] {
              //          meter.streamHandler( value)
              let newValue = Int16(bitPattern: value)
              let previousValue = meter.value
              
              // check for unknown Units
              guard let token = MeterUnits(rawValue: meter.units) else {
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
                ApiModel.shared.meters[id: id]?.value = value
              }
            }
          }
        }
      }
    }
  }
}
