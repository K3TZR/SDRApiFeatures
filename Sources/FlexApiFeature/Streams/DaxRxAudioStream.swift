//
//  DaxRxAudioStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 7/28/24.
//

import Accelerate
import AVFoundation
import Foundation

import AudioFeature
import SharedFeature
import VitaFeature

//  DATA FLOW (Reduced Bandwidth)
//
//  Audio Processor  ->  PcmProcessor  ->  Ring Buffer   ->  Output device
//
//                  [UInt8]            [Float]           [Float]           set by hardware
//
//                  Int16              pcmFloat32        pcmFloat32
//                  24_000             24_000            24_000
//                  1 channels         2 channels        2 channels
//                                     non-interleaved   non-interleaved

//  DATA FLOW (Normal Bandwidth)
//
//  Audio Processor  ->  PcmProcessor  ->  Ring Buffer   ->  Output device
//
//                  [Float]            [Float]           [Float]           set by hardware
//
//                  pcmFloat32         pcmFloat32        pcmFloat32
//                  24_000             24_000            24_000
//                  2 channels         2 channels        2 channels
//                  interleaved        non-interleaved   non-interleave

public actor DaxRxAudioStream: Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var channel = 0
  public let sampleRate: Double
  public let levelsEnabled: Bool
  public let channelCount = 2
  
  public var levels = SignalLevel(rms: -50,peak: -50) // accessed by a View
  public var status = "Off"
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _engine = AVAudioEngine()
  private let _minDbLevel: Float = -50
  private var _pcmProcessor: PcmProcessor!
  private var _ringBuffer: RingBuffer!

  private var _ringBufferAsbd: AudioStreamBasicDescription
  private var _srcNode: AVAudioSourceNode!

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, sampleRate: Double = 24_000, levelsEnabled: Bool = true) {
    self.id = id
    self.sampleRate = sampleRate
    self.levelsEnabled = levelsEnabled

    // PCM, Float32, Host, 2 channel, non-interleaved
    _ringBufferAsbd = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                  mFormatID: kAudioFormatLinearPCM,
                                                  mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                  mBytesPerPacket: UInt32(MemoryLayout<Float>.size ),
                                                  mFramesPerPacket: 1,
                                                  mBytesPerFrame: UInt32(MemoryLayout<Float>.size ),
                                                  mChannelsPerFrame: UInt32(channelCount),
                                                  mBitsPerChannel: UInt32(MemoryLayout<Float>.size  * 8) ,
                                                  mReserved: 0)
    _ringBuffer = RingBuffer(_ringBufferAsbd)
    _pcmProcessor = PcmProcessor(_ringBufferAsbd, _ringBuffer)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start(_ channel: Int) async {
    self.channel = channel
    
    _srcNode = AVAudioSourceNode { [self] _, _, frameCount, audioBufferList -> OSStatus in
      // retrieve the requested number of frames
      self._ringBuffer.deque(audioBufferList, frameCount)
      return noErr
    }
    
    _engine.attach(_srcNode)
    _engine.connect(_srcNode,
                    to: _engine.mainMixerNode,
                    format: AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                          sampleRate: sampleRate,
                                          channels: AVAudioChannelCount(RxAudioOutput.channelCount),
                                          interleaved: false)!)
    
    // empty the ring buffer
    _ringBuffer.clear()
    
    do {
      try _engine.start()
      apiLog.debug("DaxRxAudioStream: output STARTED, Stream Id = \(self.id.hex)")

      let availableFrames = _ringBuffer.availableFrames()
      apiLog.debug("DaxRxAudioStream start: available frames = \(availableFrames)")
      
      if levelsEnabled {
        // use a Tap to inspect the data and calculate average and peak levels
        _engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) {(buffer, time) in
          guard buffer.floatChannelData?[0] != nil else {return}
          
          // NOTE: the levels property is marked @MainActor therefore this requires async updating on the MainActor
//          Task { await MainActor.run {
          self.levels = self.levelCalc(buffer)
//          }}
        }
      }
      
    } catch {
      apiLog.error("DaxRxAudioStream: Failed to start, error = \(error)")
    }
    
  }
  
  public func stop() {
    apiLog.debug("DaxRxAudioStream: output STOPPED, Stream Id = \(self.id.hex)")
    _engine.mainMixerNode.removeTap(onBus: 0)
    _engine.stop()
    
    //    if levelsEnabled {
    //      // NOTE: the levels property is marked @MainActor therefore this requires async updating on the MainActor
    //      Task { await MainActor.run {
    levels = SignalLevel(rms: _minDbLevel, peak: _minDbLevel)
    //      }}
    //    }

    let availableFrames = _ringBuffer.availableFrames()
    apiLog.debug("DaxRxAudioStream stop: available frames = \(availableFrames)")
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func levelCalc(_ buffer: AVAudioPCMBuffer) -> SignalLevel {
    guard let channelData = buffer.floatChannelData?[0] else  { return SignalLevel(rms: _minDbLevel, peak: _minDbLevel) }
    let frames = buffer.frameLength

    // calc the average
    var rms: Float = 0
    vDSP_measqv(channelData, 1, &rms, UInt(frames))
    var rmsDb = 10*log10f(rms)
    if rmsDb < _minDbLevel {
      rmsDb = _minDbLevel
    }
    // calc the peak
    var max: Float = 0
    vDSP_maxv(channelData, 1, &max, UInt(frames))
    var maxDb = 10*log10f(max)
    if maxDb < _minDbLevel {
      maxDb = _minDbLevel
    }
    return SignalLevel(rms: rmsDb, peak: maxDb)
  }
  
//  public func setDevice(_ deviceId: AudioDeviceID) {
//    self.deviceId = deviceId
//    //      print("--->>> DaxAudioPlayer: DeviceId = \(deviceId)")
//
//    // get the audio unit from the output node
//    let outputUnit = _engine.outputNode.audioUnit!
//    // use core audio to set the output device:
//    var outputDevice: AudioDeviceID = deviceId
//    AudioUnitSetProperty(outputUnit,
//                         kAudioOutputUnitProperty_CurrentDevice,
//                         kAudioUnitScope_Global,
//                         0,
//                         &outputDevice,
//                         UInt32(MemoryLayout<AudioDeviceID>.size))
//  }
  
  public func setGain(_ gain: Double) {
//    self.gain = gain
//    if let streamId = streamId {
//      Task {
//        if let sliceLetter = StreamModel.shared.daxRxAudioStreams[id: streamId]?.sliceLetter {
//          for slice in await ObjectModel.shared.slices where await slice.sliceLetter == sliceLetter {
//            if StreamModel.shared.daxRxAudioStreams[id: streamId]?.clientHandle == ApiModel.shared.connectionHandle {
//              await ApiModel.shared.sendCommand("audio stream \(streamId.hex) slice \(slice.id) gain \(Int(gain))")
//            }
//          }
//        }
//      }
//    }
  }
  
  public func setSampleRate(_ sampleRate: Int) {
//    self.sampleRate = Double(sampleRate)
//
//    // FIXME: how to update sample rate ???
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Stream Handler protocol method
  
  public func streamProcessor(_ vita: Vita) async {
    
    if vita.classCode == .daxAudioReducedBw {
      // Reduced Bandwidth DaxRxAudio
      await _pcmProcessor.process(vita.payloadData, reducedBandwidth: true)

    } else {
      // Full Bandwidth DaxRxAudio
      await _pcmProcessor.process(vita.payloadData)
    }
  }
}
