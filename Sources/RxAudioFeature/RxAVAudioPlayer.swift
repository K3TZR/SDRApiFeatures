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

import RingBufferFeature
import SharedFeature
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
public final class RxAVAudioPlayer: RxAudioHandler {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var streamId: UInt32?
  
  // ----------------------------------------------------------------------------
  // MARK: - Static properties
  
  private static let channelCount = 2
  private static let frameCountOpus = 240
  private static let frameCountUncompressed = 128
  private static let pcmElementSize = MemoryLayout<Float>.size   // Bytes
  private static let sampleRate: Double = 24_000
  
  private static let ringBufferCapacity = 20      // number of AudioBufferLists in the Ring buffer
  private static let ringBufferOverage  = 2_048   // allowance for Ring buffer metadata (in Bytes)
  // uses the larger frameCountOpus (vs frameCountUncompressed), size is somewhat arbitrary
  private static let ringBufferSize = (frameCountOpus * pcmElementSize * channelCount * ringBufferCapacity) + ringBufferOverage
  private static var ringBuffer = TPCircularBuffer()
  
  // Opus, UInt8, 2 channel (buffer used to store incoming Opus encoded samples)
  private static var opusASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                            mFormatID: kAudioFormatOpus,
                                                            mFormatFlags: 0,
                                                            mBytesPerPacket: 0,
                                                            mFramesPerPacket: UInt32(frameCountOpus),
                                                            mBytesPerFrame: 0,
                                                            mChannelsPerFrame: UInt32(channelCount),
                                                            mBitsPerChannel: 0,
                                                            mReserved: 0)
  // PCM, Float32, 2 channel, interleaved
  private static var opusInterleavedASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                                       mFormatID: kAudioFormatLinearPCM,
                                                                       mFormatFlags: kAudioFormatFlagIsFloat,
                                                                       mBytesPerPacket: UInt32(pcmElementSize * channelCount),
                                                                       mFramesPerPacket: 1,
                                                                       mBytesPerFrame: UInt32(pcmElementSize * channelCount),
                                                                       mChannelsPerFrame: UInt32(channelCount),
                                                                       mBitsPerChannel: UInt32(pcmElementSize * 8),
                                                                       mReserved: 0)
  
  // PCM, BigEndian Float32, 2 channel, interleaved
  private static var interleavedASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                                   mFormatID: kAudioFormatLinearPCM,
                                                                   mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian,
                                                                   mBytesPerPacket: UInt32(pcmElementSize * channelCount),
                                                                   mFramesPerPacket: 1,
                                                                   mBytesPerFrame: UInt32(pcmElementSize * channelCount),
                                                                   mChannelsPerFrame: UInt32(channelCount),
                                                                   mBitsPerChannel: UInt32(pcmElementSize * 8),
                                                                   mReserved: 0)
  
  // PCM, Float32, 2 channel, non-interleaved (used by the Ring Buffer and played by the AVAudioEngine)
  private static var nonInterleavedASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                                      mFormatID: kAudioFormatLinearPCM,
                                                                      mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                                      mBytesPerPacket: UInt32(pcmElementSize),
                                                                      mFramesPerPacket: 1,
                                                                      mBytesPerFrame: UInt32(pcmElementSize),
                                                                      mChannelsPerFrame: UInt32(2),
                                                                      mBitsPerChannel: UInt32(pcmElementSize * 8) ,
                                                                      mReserved: 0)
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  // convert from Opus -> PCM Float32, 2 channel, interleaved
  private var _opusConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &RxAVAudioPlayer.opusASBD)!,
                                                to: AVAudioFormat(streamDescription: &RxAVAudioPlayer.opusInterleavedASBD)!)
  private var _interleaveConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &RxAVAudioPlayer.interleavedASBD)!,
                                                      to: AVAudioFormat(streamDescription: &RxAVAudioPlayer.nonInterleavedASBD)!)
  private var _opusInterleaveConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &RxAVAudioPlayer.opusInterleavedASBD)!,
                                                          to: AVAudioFormat(streamDescription: &RxAVAudioPlayer.nonInterleavedASBD)!)
  private var _engine = AVAudioEngine()
  private var _interleavedBuffer = AVAudioPCMBuffer()
  private var _nonInterleavedBuffer = AVAudioPCMBuffer()
  private var _opusBuffer = AVAudioCompressedBuffer()
  private var _opusPcmBuffer = AVAudioPCMBuffer()
//  private var _pcmBuffer = AVAudioPCMBuffer()
  
  // ----------------------------------------------------------------------------
  // MARK: - SourceNode (renderProc)
  
  private let _srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
    // retrieve the requested number of frames
    var lengthInFrames = frameCount
    TPCircularBufferDequeueBufferListFrames(&RxAVAudioPlayer.ringBuffer, &lengthInFrames, audioBufferList, nil, &RxAVAudioPlayer.nonInterleavedASBD)
    
    return noErr
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
//  public static var shared = RxAVAudioPlayer()
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func setup(outputDeviceID: AudioDeviceID?, volume: Float?, isCompressed: Bool = true) {
    _engine.attach(_srcNode)
    _engine.connect(_srcNode, to: _engine.mainMixerNode, format: AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 2, interleaved: false)!)
    
    // let system control the volume unless specified
    if volume != nil { _engine.mainMixerNode.outputVolume = volume! }
    
    if isCompressed {
      // Opus, UInt8, 2 channel: used for the received opus data
      _opusBuffer = AVAudioCompressedBuffer(format: AVAudioFormat(streamDescription: &RxAVAudioPlayer.opusASBD)!, packetCapacity: 1, maximumPacketSize: RxAVAudioPlayer.frameCountOpus)
      
      // Float32, Host, 2 Channel, interleaved
      _interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &RxAVAudioPlayer.opusInterleavedASBD)!, frameCapacity: UInt32(RxAVAudioPlayer.frameCountOpus))!
      _interleavedBuffer.frameLength = _interleavedBuffer.frameCapacity

      // Float32, Host, 2 Channel, non-interleaved
      _nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &RxAVAudioPlayer.nonInterleavedASBD)!, frameCapacity: UInt32(RxAVAudioPlayer.frameCountOpus * 2))!
      _nonInterleavedBuffer.frameLength = _nonInterleavedBuffer.frameCapacity

    } else {
      // Float32, BigEndian, 2 Channel, interleaved
      _interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &RxAVAudioPlayer.interleavedASBD)!, frameCapacity: UInt32(RxAVAudioPlayer.frameCountUncompressed))!
      _interleavedBuffer.frameLength = _interleavedBuffer.frameCapacity

      // Float32, Host, 2 Channel, non-interleaved
      _nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &RxAVAudioPlayer.nonInterleavedASBD)!, frameCapacity: UInt32(RxAVAudioPlayer.frameCountUncompressed * 2))!
      _nonInterleavedBuffer.frameLength = _nonInterleavedBuffer.frameCapacity
    }
    // create the Float32, Host, non-interleaved Ring buffer (actual size will be adjusted to fit virtual memory page size)
    guard _TPCircularBufferInit( &RxAVAudioPlayer.ringBuffer, UInt32(RxAVAudioPlayer.ringBufferSize), MemoryLayout<TPCircularBuffer>.stride ) else { fatalError("Ring Buffer not created") }

    // used the default output unless specified
    if outputDeviceID != nil { setOutputDevice(outputDeviceID!) }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start(_ streamId: UInt32) {
    self.streamId = streamId
    
    // empty the ring buffer
    TPCircularBufferClear(&RxAVAudioPlayer.ringBuffer)
    
    let availableFrames = TPCircularBufferGetAvailableSpace(&RxAVAudioPlayer.ringBuffer, &RxAVAudioPlayer.nonInterleavedASBD)
    log("RxAVAudioPlayer: STARTED, frames = \(availableFrames)", .debug, #function, #file, #line)
    
    // start processing
    do {
      try _engine.start()
    } catch {
      fatalError("RxAVAudioPlayer: Failed to start, error = \(error)")
    }
  }
  
  public func stop() {
    // stop processing
    _engine.stop()
    
    let availableFrames = TPCircularBufferGetAvailableSpace(&RxAVAudioPlayer.ringBuffer, &RxAVAudioPlayer.nonInterleavedASBD)
    log("RxAVAudioPlayer: STOPPED, frames = \(availableFrames) ", .debug, #function, #file, #line)
  }
  
  public func volume(_ level: Float) {
    _engine.mainMixerNode.outputVolume = level
  }

  public func mute(_ mute: Bool) {
    if mute {
      if _engine.isRunning { _engine.stop() }
    } else {
      if !_engine.isRunning { try! _engine.start() }
    }
    
  }

  public func setOutputDevice(_ deviceID: AudioDeviceID) {
    // get the audio unit from the output node
    let outputUnit = _engine.outputNode.audioUnit!
    // use core audio to set the output device:
    var outputDeviceID: AudioDeviceID = deviceID
    AudioUnitSetProperty(outputUnit,
                         kAudioOutputUnitProperty_CurrentDevice,
                         kAudioUnitScope_Global,
                         0,
                         &outputDeviceID,
                         UInt32(MemoryLayout<AudioDeviceID>.size))
  }

  // ----------------------------------------------------------------------------
  // MARK: - Stream Handler protocol method
  
  /// Process the UDP Stream Data for RemoteRxAudioStream streams
  public func rxAudioHandler(payload: [UInt8], compressed: Bool) {
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
        TPCircularBufferCopyAudioBufferList(&RxAVAudioPlayer.ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(RxAVAudioPlayer.frameCountOpus), &RxAVAudioPlayer.nonInterleavedASBD)
        
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
        TPCircularBufferCopyAudioBufferList(&RxAVAudioPlayer.ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(RxAVAudioPlayer.frameCountUncompressed), &RxAVAudioPlayer.nonInterleavedASBD)
        
      } catch {
        log("DaxRxAudioPlayer: Conversion error = \(error)", .error, #function, #file, #line)
      }
    }
  }
}
