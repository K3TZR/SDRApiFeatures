//
//  RxAVAudioPlayer.swift
//  UtilityFeatures/RxAVAudioPlayer
//
//  Created by Douglas Adams on 11/29/23.
//  Copyright © 2023 Douglas Adams. All rights reserved.
//

import Accelerate
import AudioToolbox
import AVFoundation
import Foundation

import FlexApiFeature
import RingBufferFeature
import SharedFeature
import VitaFeature
import XCGLogFeature

//  DATA FLOW (COMPRESSED)
//
//  Stream Handler  ->  Opus Decoder   ->   Ring Buffer   ->  OutputUnit    -> Output device
//
//                  [UInt8]            [Float]            [Float]           set by hardware
//
//                  opus               pcmFloat32         pcmFloat32
//                  24_000             24_000             24_000
//                  2 channels         2 channels         2 channels
//                                     interleaved        interleaved

//  DATA FLOW (NOT COMPRESSED)
//
//  Stream Handler  ->   Ring Buffer   ->  OutputUnit    -> Output device
//
//                  [Float]            [Float]           set by hardware
//
//                  pcmFloat32         pcmFloat32
//                  24_000             24_000
//                  2 channels         2 channels
//                  interleaved        interleaved

@Observable
public final class RxAudioPlayer: Equatable, AudioProcessor {
  public static func == (lhs: RxAudioPlayer, rhs: RxAudioPlayer) -> Bool {
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var active = false
  public var streamId: UInt32?
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _interleavedBigEndianASBD: AudioStreamBasicDescription!
  private var _nonInterleavedASBD: AudioStreamBasicDescription!
  private var _opusASBD: AudioStreamBasicDescription!
  private var _opusInterleavedASBD: AudioStreamBasicDescription!
  
  private var _srcNode: AVAudioSourceNode!
  private var _opusConverter: AVAudioConverter!
  private var _interleaveConverter: AVAudioConverter!
  private var _opusInterleaveConverter: AVAudioConverter!
  
  // ring buffer uses the larger frameCountOpus (vs frameCountUncompressed), size is somewhat arbitrary
  private var _frameCountOpus = 240
  private var _frameCountUncompressed = 128
  
  private let _sampleRate: Double = 24_000
  private let _channelCount = 2
  private let _elementSize = MemoryLayout<Float>.size   // Bytes
  private var _ringBufferCapacity = 20      // number of AudioBufferLists in the Ring buffer
  private var _ringBufferOverage  = 2_048   // allowance for Ring buffer metadata (in Bytes)
  private var _ringBuffer = TPCircularBuffer()
  
  private var _engine = AVAudioEngine()
  private var _interleavedBuffer = AVAudioPCMBuffer()
  private var _nonInterleavedBuffer = AVAudioPCMBuffer()
  private var _opusBuffer = AVAudioCompressedBuffer()
  private var _opusPcmBuffer = AVAudioPCMBuffer()
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init() {
    
    // Opus, UInt8, 2 channel (buffer used to store incoming Opus encoded samples)
    _opusASBD = AudioStreamBasicDescription(mSampleRate: _sampleRate,
                                            mFormatID: kAudioFormatOpus,
                                            mFormatFlags: 0,
                                            mBytesPerPacket: 0,
                                            mFramesPerPacket: UInt32(_frameCountOpus),
                                            mBytesPerFrame: 0,
                                            mChannelsPerFrame: UInt32(_channelCount),
                                            mBitsPerChannel: 0,
                                            mReserved: 0)
    // PCM, Float32, Host, 2 channel, interleaved
    _opusInterleavedASBD = AudioStreamBasicDescription(mSampleRate: _sampleRate,
                                                       mFormatID: kAudioFormatLinearPCM,
                                                       mFormatFlags: kAudioFormatFlagIsFloat,
                                                       mBytesPerPacket: UInt32(_elementSize * _channelCount),
                                                       mFramesPerPacket: 1,
                                                       mBytesPerFrame: UInt32(_elementSize * _channelCount),
                                                       mChannelsPerFrame: UInt32(_channelCount),
                                                       mBitsPerChannel: UInt32(_elementSize * 8),
                                                       mReserved: 0)
    
    // PCM, Float32, BigEndian, 2 channel, interleaved
    _interleavedBigEndianASBD = AudioStreamBasicDescription(mSampleRate: _sampleRate,
                                                            mFormatID: kAudioFormatLinearPCM,
                                                            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian,
                                                            mBytesPerPacket: UInt32(_elementSize * _channelCount),
                                                            mFramesPerPacket: 1,
                                                            mBytesPerFrame: UInt32(_elementSize * _channelCount),
                                                            mChannelsPerFrame: UInt32(_channelCount),
                                                            mBitsPerChannel: UInt32(_elementSize * 8),
                                                            mReserved: 0)
    
    // PCM, Float32, Host, 2 channel, non-interleaved (used by the Ring Buffer and played by the AVAudioEngine)
    _nonInterleavedASBD = AudioStreamBasicDescription(mSampleRate: _sampleRate,
                                                      mFormatID: kAudioFormatLinearPCM,
                                                      mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                      mBytesPerPacket: UInt32(_elementSize),
                                                      mFramesPerPacket: 1,
                                                      mBytesPerFrame: UInt32(_elementSize),
                                                      mChannelsPerFrame: UInt32(2),
                                                      mBitsPerChannel: UInt32(_elementSize * 8) ,
                                                      mReserved: 0)
    
    
    _opusConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &_opusASBD)!,
                                      to: AVAudioFormat(streamDescription: &_opusInterleavedASBD)!)
    _interleaveConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &_interleavedBigEndianASBD)!,
                                            to: AVAudioFormat(streamDescription: &_nonInterleavedASBD)!)
    _opusInterleaveConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &_opusInterleavedASBD)!,
                                                to: AVAudioFormat(streamDescription: &_nonInterleavedASBD)!)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start(isCompressed: Bool = true) {
    
    if isCompressed {
      // Opus, UInt8, 2 channel: used for the received opus data
      _opusBuffer = AVAudioCompressedBuffer(format: AVAudioFormat(streamDescription: &_opusASBD)!, packetCapacity: 1, maximumPacketSize: _frameCountOpus)
      
      // Float32, Host, 2 Channel, interleaved
      _interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &_opusInterleavedASBD)!, frameCapacity: UInt32(_frameCountOpus))!
      _interleavedBuffer.frameLength = _interleavedBuffer.frameCapacity
      
      // Float32, Host, 2 Channel, non-interleaved
      _nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &_nonInterleavedASBD)!, frameCapacity: UInt32(_frameCountOpus * _channelCount))!
      _nonInterleavedBuffer.frameLength = _nonInterleavedBuffer.frameCapacity
      
    } else {
      // Float32, BigEndian, 2 Channel, interleaved
      _interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &_interleavedBigEndianASBD)!, frameCapacity: UInt32(_frameCountUncompressed))!
      _interleavedBuffer.frameLength = _interleavedBuffer.frameCapacity
      
      // Float32, Host, 2 Channel, non-interleaved
      _nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &_nonInterleavedASBD)!, frameCapacity: UInt32(_frameCountUncompressed * _channelCount))!
      _nonInterleavedBuffer.frameLength = _nonInterleavedBuffer.frameCapacity
    }
    // create the Float32, Host, non-interleaved Ring buffer (actual size will be adjusted to fit virtual memory page size)
    let ringBufferSize = (_frameCountOpus * _elementSize * _channelCount * _ringBufferCapacity) + _ringBufferOverage
    guard _TPCircularBufferInit( &_ringBuffer, UInt32(ringBufferSize), MemoryLayout<TPCircularBuffer>.stride ) else { fatalError("RxAudioPlayer: Ring Buffer not created") }
    
    _srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
      // retrieve the requested number of frames
      var lengthInFrames = frameCount
      TPCircularBufferDequeueBufferListFrames(&self._ringBuffer, &lengthInFrames, audioBufferList, nil, &self._nonInterleavedASBD)
      return noErr
    }
    
    _engine.attach(_srcNode)
    _engine.connect(_srcNode, to: _engine.mainMixerNode, format: AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                                                               sampleRate: _sampleRate,
                                                                               channels: AVAudioChannelCount(_channelCount),
                                                                               interleaved: false)!)
    active = true
    
    // empty the ring buffer
    TPCircularBufferClear(&_ringBuffer)
    
    // start processing
    do {
      try _engine.start()
    } catch {
      fatalError("RxAudioPlayer: Failed to start, error = \(error)")
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func stop() {
    // stop processing
    _engine.stop()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Audio Processor protocol method
  
  /// Process the UDP Stream Data for RemoteRxAudioStream streams
//  public func rxAudioHandler(payload: [UInt8], compressed: Bool) {
  public func audioProcessor(_ vita: Vita) {
    let payload = vita.payloadData
    let compressed = vita.classCode == .opus
    
    let totalBytes = payload.count
    
    if compressed {
      // OPUS Compressed RemoteRxAudio
      
      if totalBytes != 0 {
        // Valid packet: copy the data and save the count
        memcpy(_opusBuffer.data, payload, totalBytes)
        _opusBuffer.byteLength = UInt32(totalBytes)
        _opusBuffer.packetCount = AVAudioPacketCount(1)
        _opusBuffer.packetDescriptions![0].mDataByteSize = _opusBuffer.byteLength
      } else {
        // Missed packet:
        _opusBuffer.byteLength = UInt32(totalBytes)
        _opusBuffer.packetCount = AVAudioPacketCount(1)
        _opusBuffer.packetDescriptions![0].mDataByteSize = _opusBuffer.byteLength
      }
      // Convert Opus UInt8 -> PCM Float32, Host, interleaved
      var error: NSError?
      _ = _opusConverter!.convert(to: _interleavedBuffer, error: &error, withInputFrom: { (_, outputStatus) -> AVAudioBuffer? in
        outputStatus.pointee = .haveData
        return self._opusBuffer
      })
      
      // check for decode errors
      if error != nil { fatalError("Opus conversion error: \(error!)") }
      
      // convert interleaved, BigEndian -> non-interleaved, Host
      do {
        try _opusInterleaveConverter!.convert(to: _nonInterleavedBuffer, from: _interleavedBuffer)
        // append the data to the Ring buffer
        TPCircularBufferCopyAudioBufferList(&_ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(_frameCountOpus), &_nonInterleavedASBD)
        
      } catch {
        log("DaxRxAudioPlayer: Conversion error = \(error)", .error, #function, #file, #line)
      }
      
    } else {
      // UN-Compressed RemoteRxAudio, payload is Float32, BigEndian, interleaved
      
      // copy the data to the buffer
      memcpy(_interleavedBuffer.floatChannelData![0], payload, totalBytes)
      
      // convert Float32, BigEndian, interleaved -> Float32, Host, non-interleaved
      do {
        try _interleaveConverter!.convert(to: _nonInterleavedBuffer, from: _interleavedBuffer)
        // append the data to the Ring buffer
        TPCircularBufferCopyAudioBufferList(&_ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(_frameCountUncompressed), &_nonInterleavedASBD)
        
      } catch {
        log("RemoteRxAudioPlayer: Conversion error = \(error)", .error, #function, #file, #line)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Stream reply handler
  
  public func streamReplyHandler(_ command: String, _ seqNumber: Int, _ responseValue: String, _ reply: String) {
    if responseValue == kNoError  {
      if let streamId = reply.streamId {
        self.streamId = streamId
        
        start()
        StreamModel.shared.remoteRxAudioStreams[id: streamId]?.delegate = self
        log("RemoteRxAudioPlayer: audioOutput STARTED, Stream Id = \(streamId.hex)", .debug, #function, #file, #line)
      }
    }
  }
}
