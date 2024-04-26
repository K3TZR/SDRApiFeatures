//
//  DaxTxAudioStream.swift
//  FlexApiFeature/Streams
//
//  Created by Mario Illgen on 27.03.17.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import AVFoundation
import Foundation

import SharedFeature
import UdpFeature
import VitaFeature
import XCGLogFeature

// DaxTxAudioStream
//      creates a DaxTxAudioStream instance to be used by a Client to support the
//      processing of a stream of Audio from the client to the Radio. DaxTxAudioStream
//      instances are added / removed by the incoming TCP messages. DaxTxAudioStream
//      instances periodically send Tx Audio in a UDP stream. They are collected in
//      the Model.daxTxAudioStreams collection.
@Observable
public final class DaxTxAudioStream: Identifiable, Equatable {
  public static func == (lhs: DaxTxAudioStream, rhs: DaxTxAudioStream) -> Bool {
    lhs.id == rhs.id
  }

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) { self.id = id  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var initialized = false
  public var isStreaming = false

  public var delegate: DaxAudioInputHandler?

  public var clientHandle: UInt32 = 0
  public var ip = ""
  public var isTransmitChannel = false
  public var txGain = 0 {
    didSet { if txGain != oldValue {
      if txGain == 0 {
        txGainScalar = 0.0
        return
      }
      let db_min:Float = -10.0
      let db_max:Float = +10.0
      let db:Float = db_min + (Float(txGain) / 100.0) * (db_max - db_min)
      txGainScalar = pow(10.0, db / 20.0)
    }}}
  public var txGainScalar: Float = 0
  
 public enum Property: String {
    case clientHandle      = "client_handle"
    case ip
    case isTransmitChannel = "tx"
    case type
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _txSequenceNumber: UInt8 = 0
  private var _vita: Vita?

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  /// Parse key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown keys
      guard let token = Property(rawValue: property.key) else {
        // unknown Key, log it and ignore the Key
        log("DaxTxAudioStream \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // known keys, in alphabetical order
      switch token {
        
      case .clientHandle:       clientHandle = property.value.handle ?? 0
      case .ip:                 ip = property.value
      case .isTransmitChannel:  isTransmitChannel = property.value.bValue
      case .type:               break  // included to inhibit unknown token warnings
      }
    }
    // is it initialized?
    if initialized == false && clientHandle != 0 {
      // NO, it is now
      initialized = true
      log("DaxTxAudioStream \(id.hex) ADDED: handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }


  
  
  public func send(_ buffer: AVAudioPCMBuffer) {
    
  }
  
  
  
  
  /// Send Tx Audio to the Radio
  /// - Parameters:
  ///   - left:                   array of left samples
  ///   - right:                  array of right samples
  ///   - samples:                number of samples
  /// - Returns:                  success
  public func sendTXAudio(radio: Radio, left: [Float], right: [Float], samples: Int, sendReducedBW: Bool = false) -> Bool {
    var samplesSent = 0
    var samplesToSend = 0
    
    // skip this if we are not the DAX TX Client
    guard isTransmitChannel else { return false }
    
    // get a TxAudio Vita
    if _vita == nil { _vita = Vita(type: .txAudio, streamId: id, reducedBW: sendReducedBW) }
    
    let kMaxSamplesToSend = 128     // maximum packet samples (per channel)
    let kNumberOfChannels = 2       // 2 channels
    
    if sendReducedBW {
      // REDUCED BANDWIDTH
      // create new array for payload (mono samples)
      var uint16Array = [UInt16](repeating: 0, count: kMaxSamplesToSend)
      
      while samplesSent < samples {
        // how many samples this iteration? (kMaxSamplesToSend or remainder if < kMaxSamplesToSend)
        samplesToSend = min(kMaxSamplesToSend, samples - samplesSent)
        
        // interleave the payload & scale with tx gain
        for i in 0..<samplesToSend {
          var floatSample = left[i + samplesSent] * txGainScalar
          
          if floatSample > 1.0 {
            floatSample = 1.0
          } else if floatSample < -1.0 {
            floatSample = -1.0
          }
          let intSample = Int16(floatSample * 32767.0)
          uint16Array[i] = CFSwapInt16HostToBig(UInt16(bitPattern: intSample))
        }
        _vita!.payloadData = uint16Array.withUnsafeBytes { Array($0) }
        
        // set the length of the packet
        _vita!.payloadSize = samplesToSend * MemoryLayout<Int16>.size            // 16-Bit mono samples
        _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size   // payload size + header size
        
        // set the sequence number
//        _vita!.sequence = _txSequenceNumber
        
        // encode the Vita class as data and send to radio
        
        // FIXME: need sequence number ???
        
        if let vitaData = Vita.encodeAsData(_vita!, sequenceNumber: _txSequenceNumber) { Udp.shared.send(vitaData ) }
        
        // increment the sequence number (mod 16)
        _txSequenceNumber = (_txSequenceNumber + 1) % 16
        
        // adjust the samples sent
        samplesSent += samplesToSend
      }
      
    } else {
      // NORMAL BANDWIDTH
      // create new array for payload (interleaved L/R stereo samples)
      var floatArray = [Float](repeating: 0, count: kMaxSamplesToSend * kNumberOfChannels)
      
      while samplesSent < samples {
        // how many samples this iteration? (kMaxSamplesToSend or remainder if < kMaxSamplesToSend)
        samplesToSend = min(kMaxSamplesToSend, samples - samplesSent)
        let numFloatsToSend = samplesToSend * kNumberOfChannels
        
        // interleave the payload & scale with tx gain
        for i in 0..<samplesToSend {                                         // TODO: use Accelerate
          floatArray[2 * i] = left[i + samplesSent] * txGainScalar
          floatArray[(2 * i) + 1] = left[i + samplesSent] * txGainScalar
        }
        floatArray.withUnsafeMutableBytes{ bytePtr in
          let uint32Ptr = bytePtr.bindMemory(to: UInt32.self)
          
          // swap endianess of the samples
          for i in 0..<numFloatsToSend {
            uint32Ptr[i] = CFSwapInt32HostToBig(uint32Ptr[i])
          }
        }
        _vita!.payloadData = floatArray.withUnsafeBytes { Array($0) }
        
        // set the length of the packet
        _vita!.payloadSize = numFloatsToSend * MemoryLayout<UInt32>.size            // 32-Bit L/R samples
        _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size      // payload size + header size
        
        // set the sequence number
//        _vita!.sequence = _txSequenceNumber
        
        // encode the Vita class as data and send to radio
        
//         FIXME: need sequence number ???
        
        if let vitaData = Vita.encodeAsData(_vita!, sequenceNumber: _txSequenceNumber) { Udp.shared.send(vitaData ) }
        
        // increment the sequence number (mod 16)
        _txSequenceNumber = (_txSequenceNumber + 1) % 16
        
        // adjust the samples sent
        samplesSent += samplesToSend
      }
    }
    return true
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public set property methods
  
  /// Set a property
  /// - Parameters:
  ///   - radio:      the current radio
  ///   - id:         a DaxTxAudioStream Id
  ///   - property:   an DaxTxAudioStream Token
  ///   - value:      the new value
  public static func setProperty(radio: Radio, _ id: UInt32, property: Property, value: Any) {
    // FIXME: add commands
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Send a command to Set a DaxTxAudioStream property
  /// - Parameters:
  ///   - radio:      a Radio instance
  ///   - id:         the Id for the specified DaxTxAudioStream
  ///   - token:      the parse token
  ///   - value:      the new value
  private static func send(_ radio: Radio, _ id: UInt32, _ token: Property, _ value: Any) {
    // FIXME: add commands
  }
}
