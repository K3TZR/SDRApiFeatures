//
//  RxAudioOutput.swift
//  AudioFeature/RxAudioOutput
//
//  Created by Douglas Adams on 11/29/23.
//  Copyright © 2023 Douglas Adams. All rights reserved.
//

import AVFoundation
import Foundation

import SharedFeature
import VitaFeature

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

//public final class RxAudioOutput: AudioProcessor {
public actor RxAudioOutput {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var active = false
  public var streamId: UInt32?

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
  private var _ringBufferAsbd = AudioStreamBasicDescription(mSampleRate: RxAudioOutput.sampleRate,
                                                            mFormatID: kAudioFormatLinearPCM,
                                                            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                            mBytesPerPacket: UInt32(MemoryLayout<Float>.size ),
                                                            mFramesPerPacket: 1,
                                                            mBytesPerFrame: UInt32(MemoryLayout<Float>.size ),
                                                            mChannelsPerFrame: UInt32(RxAudioOutput.channelCount),
                                                            mBitsPerChannel: UInt32(MemoryLayout<Float>.size  * 8) ,
                                                            mReserved: 0)
  private var _srcNode: AVAudioSourceNode!
 
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ streamId: UInt32) {
    self.streamId = streamId
    _ringBuffer = RingBuffer(_ringBufferAsbd)
    _opusProcessor = OpusProcessor(_ringBufferAsbd, _ringBuffer)
    _pcmProcessor = PcmProcessor(_ringBufferAsbd, _ringBuffer)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start() {
    
    // empty the Ring Buffer
//    Task {
      self._ringBuffer.clear()
      
      //    Task {
      //      let availableFrames = await _ringBuffer.availableFrames()
      //      apiLog.debug("RxAudioPlayer start: available frames = \(availableFrames)")
      //    }
      
      // create the Audio Source for the Engine (i.e. data from the Ring Buffer)
      _srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        // retrieve the requested number of frames
        self._ringBuffer.deque(audioBufferList, frameCount)
        return noErr
      }
      
      // setup the Engine
      _engine.attach(_srcNode)
      _engine.connect(_srcNode,
                      to: _engine.mainMixerNode,
                      format: AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                            sampleRate: RxAudioOutput.sampleRate,
                                            channels: AVAudioChannelCount(RxAudioOutput.channelCount),
                                            interleaved: false)!)
      active = true
      
      
      // start the Engine
      do {
        try _engine.start()
        apiLog.debug("RxAudioPlayer: audioOutput STARTED")
      } catch {
        apiLog.error("RxAudioPlayer: Failed to start, error = \(error)")
      }
    }
//  }
  
  public func stop() {
    // stop processing
    apiLog.debug("RxAudioPlayer: audioOutput STOPPED")
    _engine.stop()

//    Task {
//      let availableFrames = await _ringBuffer.availableFrames()
//      apiLog.debug("RxAudioPlayer stop: available frames = \(availableFrames)")
//    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Audio Processor protocol method
  
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
}
