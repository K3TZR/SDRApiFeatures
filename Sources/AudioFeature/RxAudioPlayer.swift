//
//  RxAudioPlayer.swift
//  AudioFeature/RxAudioPlayer
//
//  Created by Douglas Adams on 11/29/23.
//  Copyright © 2023 Douglas Adams. All rights reserved.
//

import AVFoundation
import Foundation

//import FlexApiFeature
import SharedFeature
import VitaFeature
import XCGLogFeature

//  DATA FLOW (Opus compressed)
//
//  Audio Processor  ->  OpusProcessor ->  Ring Buffer   ->  Output device
//
//                   [UInt8]           [Float]           [Float]        set by hardware
//
//                   opus              pcmFloat32        pcmFloat32
//                   24_000            24_000            24_000
//                   2 channels        2 channels        2 channels
//                                     non-interleaved   non-interleaved

//  DATA FLOW (Non compressed)
//
//  Audio Processor  ->  PcmProcessor  ->  Ring Buffer   ->  -> Output device
//
//                   [Float]           [Float]           [Float]        set by hardware
//
//                   pcmFloat32        pcmFloat32        pcmFloat32
//                   24_000            24_000            24_000
//                   2 channels        2 channels        2 channels
//                   interleaved       non-interleaved   non-interleaved

//@Observable
public final class RxAudioPlayer: AudioProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var active = false
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Static properties

  public static let sampleRate: Double = 24_000
  public static let frameCountOpus = 240
  public static let frameCountPcm = 128
  public static let channelCount = 2
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _engine = AVAudioEngine()
  private var _opusProcessor: OpusProcessor!
  private var _pcmProcessor: PcmProcessor!
  private var _ringBuffer: RingBuffer!

  // PCM, Float32, Host, 2 channel, non-interleaved
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
      log("RxAudioPlayer: audioOutput STARTED", .debug, #function, #file, #line)
    } catch {
      log("RxAudioPlayer: Failed to start, error = \(error)", .error, #function, #file, #line)
    }
  }
  
  public func stop() {
    // stop processing
    log("RxAudioPlayer: audioOutput STOPPED", .debug, #function, #file, #line)
    _engine.stop()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Audio Processor protocol method
  
  /// Process the UDP Stream Data for RemoteRxAudioStream streams
  public func audioProcessor(_ vita: Vita) {
    
    if vita.classCode == .opus {
      // OPUS Compressed RemoteRxAudio
//      Task { await _opusProcessor.process(vita.payloadData) }
      _opusProcessor.process(vita.payloadData)

    } else {
      // UN-Compressed RemoteRxAudio
      Task { await _pcmProcessor.process(vita.payloadData) }
//      _pcmProcessor.process(vita.payloadData)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Stream reply handler
  
//  public func streamReplyHandler(_ command: String, _ seqNumber: Int, _ responseValue: String, _ reply: String) {
//    if responseValue == kNoError  {
//      if let streamId = reply.streamId {
//        self.streamId = streamId
//        
//        // add the stream to the collection
//        StreamModel.shared.remoteRxAudioStreams.append( RemoteRxAudioStream(streamId) )
//        
//        // set this player as it's delegate
////        StreamModel.shared.remoteRxAudioStreams[id: streamId]!.delegate = self
//        
//        // start processing audio
//        start()
//      }
//    }
//  }
}
