//
//  DaxAudioOutput.swift
//
//
//  Created by Douglas Adams on 11/14/23.
//

import Accelerate
import AVFoundation

import FlexApiFeature
import RingBufferFeature
import SharedFeature
import XCGLogFeature

@Observable
final public class DaxAudioOutput: Equatable, DaxAudioOutputHandler {
  public static func == (lhs: DaxAudioOutput, rhs: DaxAudioOutput) -> Bool {
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var active = false
  public var streamId: UInt32?
  public var deviceId: AudioDeviceID
  public var gain: Double
  public var sampleRate: Double
  //  public var sliceLetter: String?
  
  public var levels = SignalLevel(rms: -50,peak: -50)
  public var status = "Off"
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _nonInterleavedASBD: AudioStreamBasicDescription
  private var _interleavedBigEndianASBD: AudioStreamBasicDescription
  private var _interleavedHostASBD: AudioStreamBasicDescription
  
  private var _srcNode: AVAudioSourceNode!
  private var _converter = AVAudioConverter()
  
  private var _ringBuffer = TPCircularBuffer()
  
  private let _channelCount = 2
  private let _elementSize = MemoryLayout<Float>.size   // Bytes
  private let _frameCount = 128
  private let _ringBufferCapacity = 20        // number of AudioBufferLists in the Ring buffer
  private let _ringBufferOverage  = 2_048     // allowance for Ring buffer metadata (in Bytes)
  
  private let _engine = AVAudioEngine()
  private var _interleavedBuffer = AVAudioPCMBuffer()
  private var _nonInterleavedBuffer = AVAudioPCMBuffer()
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(deviceId: AudioDeviceID, gain: Double, sampleRate: Int = 24_000) {
    self.deviceId = deviceId
    self.gain = gain
    self.sampleRate = Double(sampleRate)
    
    // PCM, Float32, Host, 2 channel, non-interleaved
    _nonInterleavedASBD = AudioStreamBasicDescription(mSampleRate: Double(sampleRate),
                                                      mFormatID: kAudioFormatLinearPCM,
                                                      mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                      mBytesPerPacket: UInt32(_elementSize),
                                                      mFramesPerPacket: 1,
                                                      mBytesPerFrame: UInt32(_elementSize),
                                                      mChannelsPerFrame: UInt32(2),
                                                      mBitsPerChannel: UInt32(_elementSize * 8) ,
                                                      mReserved: 0)
    
    // PCM, Float32, BigEndian, 2 channel, interleaved
    _interleavedBigEndianASBD = AudioStreamBasicDescription(mSampleRate: Double(sampleRate),
                                                            mFormatID: kAudioFormatLinearPCM,
                                                            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian,
                                                            mBytesPerPacket: UInt32(_elementSize * _channelCount),
                                                            mFramesPerPacket: 1,
                                                            mBytesPerFrame: UInt32(_elementSize * _channelCount),
                                                            mChannelsPerFrame: UInt32(2),
                                                            mBitsPerChannel: UInt32(_elementSize * 8) ,
                                                            mReserved: 0)
    
    // PCM, Float32, BigEndian, 2 channel, interleaved
    _interleavedHostASBD = AudioStreamBasicDescription(mSampleRate: Double(sampleRate),
                                                       mFormatID: kAudioFormatLinearPCM,
                                                       mFormatFlags: kAudioFormatFlagIsFloat,
                                                       mBytesPerPacket: UInt32(_elementSize * _channelCount),
                                                       mFramesPerPacket: 1,
                                                       mBytesPerFrame: UInt32(_elementSize * _channelCount),
                                                       mChannelsPerFrame: UInt32(2),
                                                       mBitsPerChannel: UInt32(_elementSize * 8) ,
                                                       mReserved: 0)
    
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start() {
    active = true
    
    _interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &_interleavedBigEndianASBD)!, frameCapacity: UInt32(_frameCount))!
    _interleavedBuffer.frameLength = _interleavedBuffer.frameCapacity
    
    _nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &_nonInterleavedASBD)!, frameCapacity: UInt32(_frameCount * _channelCount))!
    _nonInterleavedBuffer.frameLength = _nonInterleavedBuffer.frameCapacity
    
    // convert from PCM Float32, BigEndian, 2 channel, interleaved -> PCM Float32, Host, 2 channel, non-interleaved
    _converter = AVAudioConverter(from: AVAudioFormat(streamDescription: &_interleavedBigEndianASBD)!,
                                  to: AVAudioFormat(streamDescription: &_nonInterleavedASBD)!)!
    // create the Ring buffer (actual size will be adjusted to fit virtual memory page size)
    let ringBufferSize = (_frameCount * _elementSize * _channelCount * _ringBufferCapacity) + _ringBufferOverage
    guard _TPCircularBufferInit( &_ringBuffer, UInt32(ringBufferSize), MemoryLayout<TPCircularBuffer>.stride ) else { fatalError("DaxAudioOutput: Ring Buffer not created") }
    
    _srcNode = AVAudioSourceNode { [self] _, _, frameCount, audioBufferList -> OSStatus in
      // retrieve the requested number of frames
      var lengthInFrames = frameCount
      TPCircularBufferDequeueBufferListFrames(&_ringBuffer, &lengthInFrames, audioBufferList, nil, &_nonInterleavedASBD)
      return noErr
    }
    
    _engine.attach(_srcNode)
    _engine.connect(_srcNode, to: _engine.mainMixerNode, format: AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: _sampleRate, channels: AVAudioChannelCount(_channelCount), interleaved: false)!)
    
    setDevice(deviceId)
    setGain(gain)
    
    do {
      try _engine.start()
      _engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) {(buffer, time) in
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        // calc the average
        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, UInt(frames))
        var rmsDb = 10*log10f(rms)
        if rmsDb < -45 {
          rmsDb = -45
        }
        // calc the peak
        var max: Float = 0
        vDSP_maxv(channelData, 1, &max, UInt(frames))
        var maxDb = 10*log10f(max)
        if maxDb < -45 {
          maxDb = -45
        }
        let levels = SignalLevel(rms: rmsDb, peak: maxDb)
        
        Task {
          await MainActor.run {
            self.levels = levels
          }
        }
      }
      
    } catch {
      fatalError("DaxAudioOutput: Failed to start, error = \(error)")
    }
    
  }
  
  public func stop() {
    _engine.mainMixerNode.removeTap(onBus: 0)
    _engine.stop()
    active = false
    Task {
      await MainActor.run {
        levels = SignalLevel(rms: -50,peak: -50)
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  public func setDevice(_ deviceId: AudioDeviceID) {
    self.deviceId = deviceId
    //      print("--->>> DaxAudioPlayer: DeviceId = \(deviceId)")
    
    // get the audio unit from the output node
    let outputUnit = _engine.outputNode.audioUnit!
    // use core audio to set the output device:
    var outputDevice: AudioDeviceID = deviceId
    AudioUnitSetProperty(outputUnit,
                         kAudioOutputUnitProperty_CurrentDevice,
                         kAudioUnitScope_Global,
                         0,
                         &outputDevice,
                         UInt32(MemoryLayout<AudioDeviceID>.size))
  }
  
  public func setGain(_ gain: Double) {
    self.gain = gain
    if let streamId = streamId {
      Task {
        if let sliceLetter = StreamModel.shared.daxRxAudioStreams[id: streamId]?.sliceLetter {
          for slice in await ApiModel.shared.slices where await slice.sliceLetter == sliceLetter {
            if await StreamModel.shared.daxRxAudioStreams[id: streamId]?.clientHandle == ApiModel.shared.connectionHandle {
              await ApiModel.shared.sendCommand("audio stream \(streamId.hex) slice \(slice.id) gain \(Int(gain))")
            }
          }
        }
      }
    }
  }
  
  public func setSampleRate(_ sampleRate: Int) {
    self.sampleRate = Double(sampleRate)
    
    // FIXME: how to update sample rate ???
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Stream Handler protocol method
  
  public func daxAudioOutputHandler(payload: [UInt8], reducedBW: Bool = false) {
    let oneOverMax: Float = 1.0 / Float(Int16.max)
    
    if reducedBW {
      // Reduced Bandwidth - Int16, BigEndian, 1 Channel
      // allocate temporary array
      var floatPayload = [Float](repeating: 0, count: payload.count / MemoryLayout<Int16>.size)
      
      payload.withUnsafeBytes { (payloadPtr) in
        // Int16 Mono Samples
        // get a pointer to the data in the payload
        let uint16Ptr = payloadPtr.bindMemory(to: UInt16.self)
        
        for i in 0..<payload.count / MemoryLayout<Int16>.size {
          let uintVal = CFSwapInt16BigToHost(uint16Ptr[i])
          // convert to Float
          let floatVal = Float(Int16(bitPattern: uintVal)) * oneOverMax
          // populate non-interleaved array of Float32
          floatPayload[i] = floatVal
        }
      }
      
      // reduced BW is mono, copy same data to Left & right channels
      memcpy(_nonInterleavedBuffer.floatChannelData![0], floatPayload, floatPayload.count * MemoryLayout<Float>.size)
      memcpy(_nonInterleavedBuffer.floatChannelData![1], floatPayload, floatPayload.count * MemoryLayout<Float>.size)
      
      // append the data to the Ring buffer
      TPCircularBufferCopyAudioBufferList(&_ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(_frameCount), &_nonInterleavedASBD)
      
    } else {
      // Full Bandwidth - Float32, BigEndian, 2 Channel, interleaved
      // copy the data to the buffer
      memcpy(_interleavedBuffer.floatChannelData![0], payload, payload.count)
      
      // convert Float32, BigEndian, 2 Channel, interleaved -> Float32, BigEndian, 2 Channel, non-interleaved
      do {
        try _converter.convert(to: _nonInterleavedBuffer, from: _interleavedBuffer)
        // append the data to the Ring buffer
        TPCircularBufferCopyAudioBufferList(&_ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(_frameCount), &_nonInterleavedASBD)
        
      } catch {
        fatalError("DaxAudioOutput: Conversion error = \(error)")
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Stream reply handler
  
  public func streamReplyHandler(_ command: String, _ seqNumber: UInt, _ responseValue: String, _ reply: String) {
    if reply != kNoError {
      if let streamId = reply.streamId {
        self.streamId = streamId
        
        start()
        StreamModel.shared.daxRxAudioStreams[id: streamId]?.delegate = self
        log("DaxAudioOutput: output STARTED, Stream Id = \(streamId.hex)", .debug, #function, #file, #line)
      }
    }
  }
}
