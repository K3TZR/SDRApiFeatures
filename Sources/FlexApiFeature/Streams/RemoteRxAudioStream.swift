//
//  RemoteRxAudioStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 11/29/23.
//  Copyright © 2023 Douglas Adams. All rights reserved.
//

import AVFoundation
import Foundation

import AudioFeature
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

public actor RemoteRxAudioStream {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public let sampleRate: Double

  // ----------------------------------------------------------------------------
  // MARK: - Public Static properties

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
  private var _ringBufferAsbd: AudioStreamBasicDescription
  private var _srcNode: AVAudioSourceNode!
 
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, sampleRate: Double = 24_000) {
    self.id = id
    self.sampleRate = sampleRate
    _ringBufferAsbd = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                  mFormatID: kAudioFormatLinearPCM,
                                                  mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                  mBytesPerPacket: UInt32(MemoryLayout<Float>.size ),
                                                  mFramesPerPacket: 1,
                                                  mBytesPerFrame: UInt32(MemoryLayout<Float>.size ),
                                                  mChannelsPerFrame: UInt32(RemoteRxAudioStream.channelCount),
                                                  mBitsPerChannel: UInt32(MemoryLayout<Float>.size  * 8) ,
                                                  mReserved: 0)
    _ringBuffer = RingBuffer(_ringBufferAsbd)
    _opusProcessor = OpusProcessor(_ringBufferAsbd, _ringBuffer)
    _pcmProcessor = PcmProcessor(_ringBufferAsbd, _ringBuffer)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start() async {
    // empty the Ring Buffer
    _ringBuffer.clear()
    
    let availableFrames = _ringBuffer.availableFrames()
    apiLog.debug("RemoteRxAudioStream start: available frames = \(availableFrames)")
    
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
                                          sampleRate: sampleRate,
                                          channels: AVAudioChannelCount(RemoteRxAudioStream.channelCount),
                                          interleaved: false)!)
    // start the Engine
    do {
      try _engine.start()
      apiLog.debug("RemoteRxAudioStream: audioOutput STARTED")
    } catch {
      apiLog.error("RemoteRxAudioStream: Failed to start, error = \(error)")
    }
  }
  
  public func stop() {
    // stop processing
    apiLog.debug("RemoteRxAudioStream: audioOutput STOPPED")
    _engine.stop()

    Task { await MainActor.run {
      ObjectModel.shared.sendTcp("stream remove \(self.id.hex)")
    }}

    let availableFrames = _ringBuffer.availableFrames()
    apiLog.debug("RemoteRxAudioStream stop: available frames = \(availableFrames)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Audio Processor protocol method
  
  /// Process the UDP Stream Data for a RemoteRxAudioStream
  public func streamProcessor(_ vita: Vita) async {
    
    if vita.classCode == .opus {
      // OPUS Compressed RemoteRxAudio
      await _opusProcessor.process(vita.payloadData)

    } else {
      // UN-Compressed RemoteRxAudio
      await _pcmProcessor.process(vita.payloadData)
    }
  }
}
