//
//  RemoteTxAudioStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 2/9/16.
//  Copyright © 2016 Douglas Adams. All rights reserved.
//

import Foundation

import SharedFeature
import VitaFeature


// RemoteTxAudioStream
//      creates a RemoteTxAudioStream instance to be used by a Client to support the
//      processing of a UDP stream of Tx Audio from the client to the Radio. The RemoteTxAudioStream
//      is added / removed by TCP messages.
public actor RemoteTxAudioStream {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init() {}
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var id : UInt32 = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  private var _txSequenceNumber = 0
  private var _vita: Vita?
  
  public func start(_ id: UInt32) {
    self.id = id
  }
  
  public func stop() -> UInt32 {
    return id
  }
  
  /// Send Tx Audio to the Radio
  /// - Parameters:
  ///   - buffer:             array of encoded audio samples
  /// - Returns:              success / failure
  public func sendAudio(_ udp: Udp, buffer: [UInt8], samples: Int) {
    
    // FIXME: This assumes Opus encoded audio
    
    // get an OpusTx Vita
    if _vita == nil { _vita = Vita(type: .opusTx, streamId: id) }
    
    // create new array for payload (interleaved L/R samples)
    _vita!.payloadData = buffer
    
    // set the length of the packet
    _vita!.payloadSize = samples                                              // 8-Bit encoded samples
    _vita!.packetSize = _vita!.payloadSize + MemoryLayout<VitaHeader>.size    // payload size + header size
    
    // set the sequence number
    _vita!.sequence = _txSequenceNumber
    
    // encode the Vita class as data and send to radio
    
    // FIXME: need sequence number ????
    
    if let vitaData = Vita.encodeAsData(_vita!, sequenceNumber: 0x00) {
      Task { await  MainActor.run {
        udp.send(vitaData)
      }}
    }
    // increment the sequence number (mod 16)
    _txSequenceNumber = (_txSequenceNumber + 1) % 16
    
  }
}
