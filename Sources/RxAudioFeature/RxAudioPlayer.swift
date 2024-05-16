//
//  RxAudioPlayer.swift
//  RxAudioFeature/RxAudioPlayer
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


final public actor OpusProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ ringBufferAsbd: AudioStreamBasicDescription, _ ringBuffer: RingBuffer) {
    self.ringBufferAsbd = ringBufferAsbd
    self.ringBuffer = ringBuffer
    
    // ----- Buffers -----
    // OPUS Float32, Host, 2 Channel, non-interleaved
    opusBuffer = AVAudioCompressedBuffer(format: AVAudioFormat(streamDescription: &self.asbd)!, packetCapacity: 1, maximumPacketSize: OpusProcessor.frameCount)
    
    // PCM Float32, Host, 2 Channel, interleaved
    interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &self.interleavedAsbd)!, frameCapacity: UInt32(OpusProcessor.frameCount))!
    interleavedBuffer.frameLength = interleavedBuffer.frameCapacity

    // PCM Float32, Host, 2 Channel, non-interleaved
    nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &self.ringBufferAsbd)!, frameCapacity: UInt32(OpusProcessor.frameCount * OpusProcessor.channelCount))!
    nonInterleavedBuffer.frameLength = nonInterleavedBuffer.frameCapacity

    // ----- Converters -----
    // Opus, UInt8, 2 channel -> PCM, Float32, Host, 2 channel, interleaved
    opusConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &self.asbd)!,
                                     to: AVAudioFormat(streamDescription: &self.interleavedAsbd)!)!
    
    // PCM, Float32, Host, 2 channel, interleaved -> PCM, Float32, Host, 2 channel, non-interleaved
    interleaveConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &self.interleavedAsbd)!,
                                           to: AVAudioFormat(streamDescription: &self.ringBufferAsbd)!)!
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private Static properties
  
  private static let sampleRate: Double = 24_000
  private static let frameCount = 240
  private static let channelCount = 2

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  // Opus, UInt8, 2 channel (buffer used to store incoming Opus encoded samples)
  private var asbd = AudioStreamBasicDescription(mSampleRate: OpusProcessor.sampleRate,
                                                 mFormatID: kAudioFormatOpus,
                                                 mFormatFlags: 0,
                                                 mBytesPerPacket: 0,
                                                 mFramesPerPacket: UInt32(OpusProcessor.frameCount),
                                                 mBytesPerFrame: 0,
                                                 mChannelsPerFrame: UInt32(OpusProcessor.channelCount),
                                                 mBitsPerChannel: 0,
                                                 mReserved: 0)
  
  // PCM, Float32, Host, 2 channel, interleaved
  private var interleavedAsbd = AudioStreamBasicDescription(mSampleRate: OpusProcessor.sampleRate,
                                                            mFormatID: kAudioFormatLinearPCM,
                                                            mFormatFlags: kAudioFormatFlagIsFloat,
                                                            mBytesPerPacket: UInt32(MemoryLayout<Float>.size * OpusProcessor.channelCount),
                                                            mFramesPerPacket: 1,
                                                            mBytesPerFrame: UInt32(MemoryLayout<Float>.size * OpusProcessor.channelCount),
                                                            mChannelsPerFrame: UInt32(OpusProcessor.channelCount),
                                                            mBitsPerChannel: UInt32(MemoryLayout<Float>.size * 8),
                                                            mReserved: 0)
  
  private let interleaveConverter: AVAudioConverter
  private var interleavedBuffer = AVAudioPCMBuffer()
  private var nonInterleavedBuffer = AVAudioPCMBuffer()
  private var opusBuffer = AVAudioCompressedBuffer()
  private let opusConverter: AVAudioConverter
  private let ringBuffer: RingBuffer
  private var ringBufferAsbd: AudioStreamBasicDescription

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func process(_ payload: [UInt8]) {
  
    // copy the payload data into an AVAudioCompressedBuffer
    if payload.count != 0 {
      // Valid packet: copy the data and save the count
      memcpy(opusBuffer.data, payload, payload.count)
      opusBuffer.byteLength = UInt32(payload.count)
      opusBuffer.packetCount = AVAudioPacketCount(1)
      opusBuffer.packetDescriptions![0].mDataByteSize = opusBuffer.byteLength
    } else {
      // Missed packet: create an empty frame
      opusBuffer.byteLength = UInt32(payload.count)
      opusBuffer.packetCount = AVAudioPacketCount(1)
      opusBuffer.packetDescriptions![0].mDataByteSize = opusBuffer.byteLength
    }
    
    // Convert Opus UInt8 -> PCM Float32, Host, 2 channel, interleaved
    var error: NSError?
    _ = opusConverter.convert(to: interleavedBuffer, error: &error, withInputFrom: { (_, outputStatus) -> AVAudioBuffer? in
      outputStatus.pointee = .haveData
      return self.opusBuffer
    })
    
    // check for decode errors
    if error != nil { fatalError("OpusProcessor: Opus conversion error: \(error!)") }
    
    do {
      try interleaveConverter.convert(to: nonInterleavedBuffer, from: interleavedBuffer)
      // append the data to the Ring buffer
      Task { await self.ringBuffer.enque(nonInterleavedBuffer.mutableAudioBufferList, UInt32(OpusProcessor.frameCount))  }
    } catch {
      log("OpusProcessor: Interleave conversion error = \(error)", .error, #function, #file, #line)
    }
  }
}



final public actor PcmProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ ringBufferAsbd: AudioStreamBasicDescription, _ ringBuffer: RingBuffer) {
    self.ringBufferAsbd = ringBufferAsbd
    self.ringBuffer = ringBuffer

    // Float32, BigEndian, 2 Channel, interleaved
    interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &interleavedBigEndianAsbd)!, frameCapacity: UInt32(PcmProcessor.frameCount * PcmProcessor.channelCount))!
    interleavedBuffer.frameLength = interleavedBuffer.frameCapacity

    // Float32, BigEndian, 2 Channel, interleaved
    nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &self.ringBufferAsbd)!, frameCapacity: UInt32(PcmProcessor.frameCount * PcmProcessor.channelCount))!
    nonInterleavedBuffer.frameLength = nonInterleavedBuffer.frameCapacity

    // PCM, Float32, BigEndian, 2 channel, interleaved -> PCM, Float32, Host, 2 channel, non-interleaved
    interleaveConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &interleavedBigEndianAsbd)!,
                                           to: AVAudioFormat(streamDescription: &self.ringBufferAsbd)!)!
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Static properties
  
  private static let channelCount = 2
  private static let frameCount = 128
  private static let sampleRate: Double = 24_000

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  // PCM, Float32, BigEndian, 2 channel, interleaved
  private var interleavedBigEndianAsbd = AudioStreamBasicDescription(mSampleRate: PcmProcessor.sampleRate,
                                                                     mFormatID: kAudioFormatLinearPCM,
                                                                     mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian,
                                                                     mBytesPerPacket: UInt32(MemoryLayout<Float>.size * PcmProcessor.channelCount),
                                                                     mFramesPerPacket: 1,
                                                                     mBytesPerFrame: UInt32(MemoryLayout<Float>.size * PcmProcessor.channelCount),
                                                                     mChannelsPerFrame: UInt32(PcmProcessor.channelCount),
                                                                     mBitsPerChannel: UInt32(MemoryLayout<Float>.size * 8),
                                                                     mReserved: 0)

  private var interleavedBuffer: AVAudioPCMBuffer
  private let interleaveConverter: AVAudioConverter
  private var nonInterleavedBuffer: AVAudioPCMBuffer
  private var ringBuffer: RingBuffer
  private var ringBufferAsbd: AudioStreamBasicDescription

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func process(_ payload: [UInt8]) {
    
    // copy the data to the buffer
    memcpy(interleavedBuffer.floatChannelData![0], payload, payload.count)

    do {
      try interleaveConverter.convert(to: nonInterleavedBuffer, from: interleavedBuffer)
      // append the data to the Ring buffer
      Task { await self.ringBuffer.enque(nonInterleavedBuffer.mutableAudioBufferList, UInt32(PcmProcessor.frameCount))  }
    } catch {
      log("PcmProcessor: Interleave conversion error = \(error)", .error, #function, #file, #line)
    }
  }
}



final public actor RingBuffer{
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ asbd: AudioStreamBasicDescription) {
    self.asbd = asbd
    _TPCircularBufferInit( &buffer, UInt32(RingBuffer.bufferSize), MemoryLayout<TPCircularBuffer>.stride )
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Static properties
  
  private static let channelCount = 2
  private static let frameCountUncompressed = 128
  private static let frameCountOpus = 240

  private static let bufferCapacity = 20      // number of AudioBufferLists in the Ring buffer
  private static let bufferOverage = 2_048    // allowance for Ring buffer metadata (in Bytes)
  private static let bufferSize = (frameCountOpus * MemoryLayout<Float>.size * channelCount * bufferCapacity) + bufferOverage

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var asbd: AudioStreamBasicDescription
  private var buffer = TPCircularBuffer()

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func deque(_ audioBufferList: UnsafeMutablePointer<AudioBufferList>, _ frameCount: AVAudioFrameCount ) {
    var frames = frameCount
    TPCircularBufferDequeueBufferListFrames(&buffer, &frames, audioBufferList, nil, &self.asbd)
  }
  
  public func enque(_ audioBufferList: UnsafeMutablePointer<AudioBufferList>, _ frameCount: UInt32) {
    TPCircularBufferCopyAudioBufferList(&buffer, audioBufferList, nil, frameCount, &self.asbd)
  }
  
  public func clear() {
    TPCircularBufferClear(&buffer)
  }
}



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

//@Observable
public final class RxAudioPlayer: AudioProcessor {
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var active = false
  public var streamId: UInt32?
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Static properties

  private static let sampleRate: Double = 24_000
  private static let frameCountOpus = 240
  private static let channelCount = 2
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _engine = AVAudioEngine()
  private var _opusProcessor: OpusProcessor
  private var _pcmProcessor: PcmProcessor
  private var _ringBuffer: RingBuffer

  // PCM, Float32, Host, 2 channel, non-interleaved (used by the Ring Buffer and played by the AVAudioEngine)
  private var _ringBufferAsbd = AudioStreamBasicDescription(mSampleRate: RxAudioPlayer.sampleRate,
                                                            mFormatID: kAudioFormatLinearPCM,
                                                            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                            mBytesPerPacket: UInt32(MemoryLayout<Float>.size ),
                                                            mFramesPerPacket: 1,
                                                            mBytesPerFrame: UInt32(MemoryLayout<Float>.size ),
                                                            mChannelsPerFrame: UInt32(RxAudioPlayer.channelCount),
                                                            mBitsPerChannel: UInt32(MemoryLayout<Float>.size  * 8) ,
                                                            mReserved: 0)
   private var _srcNode: AVAudioSourceNode!
 
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init() {
    _ringBuffer = RingBuffer(_ringBufferAsbd)
    _opusProcessor = OpusProcessor(_ringBufferAsbd, _ringBuffer)
    _pcmProcessor = PcmProcessor(_ringBufferAsbd, _ringBuffer)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start(isCompressed: Bool = true) {
    
    _srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
      // retrieve the requested number of frames
      Task { await self._ringBuffer.deque(audioBufferList, frameCount) }
      return noErr
    }
    
    _engine.attach(_srcNode)
    _engine.connect(_srcNode, 
                   to: _engine.mainMixerNode,
                   format: AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: RxAudioPlayer.sampleRate,
                                         channels: AVAudioChannelCount(RxAudioPlayer.channelCount),
                                         interleaved: false)!)
    active = true
    
    // empty the ring buffer
    Task { await self._ringBuffer.clear() }
    
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
  public func audioProcessor(_ vita: Vita) {
    
    if vita.classCode == .opus {
      // OPUS Compressed RemoteRxAudio
      Task { await _opusProcessor.process(vita.payloadData) }
      
    } else {
      // UN-Compressed RemoteRxAudio
      Task { await _pcmProcessor.process(vita.payloadData) }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Stream reply handler
  
  public func streamReplyHandler(_ command: String, _ seqNumber: Int, _ responseValue: String, _ reply: String) {
    if responseValue == kNoError  {
      if let streamId = reply.streamId {
        self.streamId = streamId
        
        StreamModel.shared.remoteRxAudioStreams.append( RemoteRxAudioStream(streamId) )
        
        StreamModel.shared.remoteRxAudioStreams[id: streamId]!.delegate = self
        log("RxAudioPlayer: audioOutput STARTED, Stream Id = \(streamId.hex)", .debug, #function, #file, #line)
        start()
      }
    }
  }
}

// AudioBufferList is protected by TPCircularBuffer logic
extension UnsafeMutablePointer<AudioBufferList> : @unchecked Sendable { }
