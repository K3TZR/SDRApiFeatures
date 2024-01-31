//
//  DaxRxAudioPlayer.swift
//
//
//  Created by Douglas Adams on 11/14/23.
//

import Accelerate
import AVFoundation

import RingBufferFeature
import SharedFeature
import XCGLogFeature

@Observable
final public class DaxRxAudioPlayer: DaxRxAudioHandler{
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var streamId: UInt32?
  public var levels = SignalLevel(rms: 0,peak: 0)
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private static let channelCount = 2
  private static let elementSize = MemoryLayout<Float>.size   // Bytes
  private static let frameCount = 128
  private static let sampleRate: Double = 24_000
 
  // PCM, Float32, Host, 2 channel, non-interleaved
  private static var nonInterleavedASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                                      mFormatID: kAudioFormatLinearPCM,
                                                                      mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved,
                                                                      mBytesPerPacket: UInt32(elementSize),
                                                                      mFramesPerPacket: 1,
                                                                      mBytesPerFrame: UInt32(elementSize),
                                                                      mChannelsPerFrame: UInt32(2),
                                                                      mBitsPerChannel: UInt32(elementSize * 8) ,
                                                                      mReserved: 0)
  
  // PCM, Float32, BigEndian, 2 channel, interleaved
  private static var interleavedBigEndianASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                                            mFormatID: kAudioFormatLinearPCM,
                                                                            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian,
                                                                            mBytesPerPacket: UInt32(elementSize * channelCount),
                                                                            mFramesPerPacket: 1,
                                                                            mBytesPerFrame: UInt32(elementSize * channelCount),
                                                                            mChannelsPerFrame: UInt32(2),
                                                                            mBitsPerChannel: UInt32(elementSize * 8) ,
                                                                            mReserved: 0)

  // PCM, Float32, BigEndian, 2 channel, interleaved
  private static var interleavedHostASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                                       mFormatID: kAudioFormatLinearPCM,
                                                                       mFormatFlags: kAudioFormatFlagIsFloat,
                                                                       mBytesPerPacket: UInt32(elementSize * channelCount),
                                                                       mFramesPerPacket: 1,
                                                                       mBytesPerFrame: UInt32(elementSize * channelCount),
                                                                       mChannelsPerFrame: UInt32(2),
                                                                       mBitsPerChannel: UInt32(elementSize * 8) ,
                                                                       mReserved: 0)

  private static let ringBufferCapacity = 20        // number of AudioBufferLists in the Ring buffer
  private static let ringBufferOverage  = 2_048     // allowance for Ring buffer metadata (in Bytes)
  private static let ringBufferSize = (frameCount * elementSize * channelCount * ringBufferCapacity) + ringBufferOverage
  private static var ringBuffer = TPCircularBuffer()

  
  
  static func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> SignalLevel {
    // calc the average
    var rms: Float = 0
    vDSP_measqv(data, 1, &rms, frameLength)
    var rmsDb = 10*log10f(rms)
    if rmsDb < -45 {
      rmsDb = -45
    }
    // calc the peak
    var max: Float = 0
    vDSP_maxv(data, 1, &max, frameLength)
    var maxDb = 10*log10f(max)
    if maxDb < -45 {
      maxDb = -45
    }
    return SignalLevel(rms: rmsDb, peak: maxDb)
  }
  
  static func interpolate(current: Float, previous: Float) -> [Float] {
    var vals = [Float](repeating: 0, count: 11)
    vals[10] = current
    vals[5] = (current + previous)/2
    vals[2] = (vals[5] + previous)/2
    vals[1] = (vals[2] + previous)/2
    vals[8] = (vals[5] + current)/2
    vals[9] = (vals[10] + current)/2
    vals[7] = (vals[5] + vals[9])/2
    vals[6] = (vals[5] + vals[7])/2
    vals[3] = (vals[1] + vals[5])/2
    vals[4] = (vals[3] + vals[5])/2
    vals[0] = (previous + vals[1])/2
    return vals
  }
  
  // convert from PCM Float32, BigEndian, 2 channel, interleaved -> PCM Float32, Host, 2 channel, non-interleaved
  private var _converter = AVAudioConverter(from: AVAudioFormat(streamDescription: &DaxRxAudioPlayer.interleavedBigEndianASBD)!,
                                            to: AVAudioFormat(streamDescription: &DaxRxAudioPlayer.nonInterleavedASBD)!)
  private let _engine = AVAudioEngine()
  private var _interleavedBuffer = AVAudioPCMBuffer()
  private var _nonInterleavedBuffer = AVAudioPCMBuffer()
  
  private var _previousRMSValue: Float = 0.3

//  private var _counter = 0
//  private var _audioUnit: AudioUnit
  
  // ----------------------------------------------------------------------------
  // MARK: - SourceNode (renderProc)
  
  private let _srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
    // retrieve the requested number of frames
    var lengthInFrames = frameCount
    TPCircularBufferDequeueBufferListFrames(&DaxRxAudioPlayer.ringBuffer, &lengthInFrames, audioBufferList, nil, &DaxRxAudioPlayer.nonInterleavedASBD)
    
    return noErr
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ outputDeviceID: AudioDeviceID) {
    _engine.attach(_srcNode)
    _engine.connect(_srcNode, to: _engine.mainMixerNode, format: AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 24000, channels: 2, interleaved: false)!)
    
    _interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &DaxRxAudioPlayer.interleavedBigEndianASBD)!, frameCapacity: UInt32(DaxRxAudioPlayer.frameCount))!
    _interleavedBuffer.frameLength = _interleavedBuffer.frameCapacity

    _nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &DaxRxAudioPlayer.nonInterleavedASBD)!, frameCapacity: UInt32(DaxRxAudioPlayer.frameCount * 2))!
    _nonInterleavedBuffer.frameLength = _nonInterleavedBuffer.frameCapacity

    // create the Ring buffer (actual size will be adjusted to fit virtual memory page size)
    guard _TPCircularBufferInit( &DaxRxAudioPlayer.ringBuffer, UInt32(DaxRxAudioPlayer.ringBufferSize), MemoryLayout<TPCircularBuffer>.stride ) else { fatalError("Ring Buffer not created") }

    setDevice(outputDeviceID)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start(_ streamId: UInt32) {
    self.streamId = streamId
    
    TPCircularBufferClear(&DaxRxAudioPlayer.ringBuffer)
    
    let availableFrames = TPCircularBufferGetAvailableSpace(&DaxRxAudioPlayer.ringBuffer, &DaxRxAudioPlayer.nonInterleavedASBD)
    log("DaxRxAudioPlayer: STARTED, frames = \(availableFrames)", .debug, #function, #file, #line)
    
    do {
      try _engine.start()
      _engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: nil) {(buffer, time) in
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        self.levels = DaxRxAudioPlayer.rms(data: channelData, frameLength: UInt(frames))
      }

    } catch {
      fatalError("DaxRxAudioPlayer: Failed to start, error = \(error)")
    }
  }
  
  public func stop() {
    _engine.mainMixerNode.removeTap(onBus: 0)
    _engine.stop()

    let availableFrames = TPCircularBufferGetAvailableSpace(&DaxRxAudioPlayer.ringBuffer, &DaxRxAudioPlayer.nonInterleavedASBD)
    log("DaxRxAudioPlayer: STOPPED, frames = \(availableFrames) ", .debug, #function, #file, #line)
  }
  
  public func setDevice(_ deviceID: AudioDeviceID) {
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
  
  public func daxRxAudioHandler(payload: [UInt8], reducedBW: Bool = false, channelNumber: Int? = nil) {
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
      
//      var level: AudioUnitParameterValue = 0
//      AudioUnitGetParameter(_audioUnit, kMultiChannelMixerParam_PostAveragePower, kAudioUnitScope_Output, 0, &level);
//      dbPower = Double(level)

//      _counter += 1
//      if _counter % 5 == 0 {
//        //Calculate the mean value of the absolute values
//        let meanValue = floatPayload.reduce(0, {$0 + abs($1)})/Float(floatPayload.count)
//        //Calculate the dB power (You can adjust this), if average is less than 0.000_000_01 we limit it to -160.0
//        dbPower = Double(meanValue > 0.000_000_01 ? 20 * log10(meanValue) : -45.0)
//        _counter = 1
//      }

      // reduced BW is mono, copy same data to Left & right channels
      memcpy(_nonInterleavedBuffer.floatChannelData![0], floatPayload, floatPayload.count * MemoryLayout<Float>.size)
      memcpy(_nonInterleavedBuffer.floatChannelData![1], floatPayload, floatPayload.count * MemoryLayout<Float>.size)

      // append the data to the Ring buffer
      TPCircularBufferCopyAudioBufferList(&DaxRxAudioPlayer.ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(DaxRxAudioPlayer.frameCount), &DaxRxAudioPlayer.nonInterleavedASBD)
      
    } else {
      // Full Bandwidth - Float32, BigEndian, 2 Channel, interleaved
      // copy the data to the buffer
      memcpy(_interleavedBuffer.floatChannelData![0], payload, payload.count)
            
      // convert Float32, BigEndian, 2 Channel, interleaved -> Float32, BigEndian, 2 Channel, non-interleaved
      do {
        try _converter!.convert(to: _nonInterleavedBuffer, from: _interleavedBuffer)
        // append the data to the Ring buffer
        TPCircularBufferCopyAudioBufferList(&DaxRxAudioPlayer.ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(DaxRxAudioPlayer.frameCount), &DaxRxAudioPlayer.nonInterleavedASBD)
        
      } catch {
        log("DaxRxAudioPlayer: Conversion error = \(error)", .error, #function, #file, #line)
      }
    }
  }
}

/*
 //This is the array of floats
  let arr = Array(UnsafeBufferPointer(start:channelData, count: frameSizeToRead))
  
  //Calculate the mean value of the absolute values
  let meanValue = arr.reduce(0, {$0 + abs($1)})/Float(arr.count)
  
  //Calculate the dB power (You can adjust this), if average is less than 0.000_000_01 we limit it to -160.0
  let dbPower: Float = meanValue > 0.000_000_01 ? 20 * log10(meanValue) : -160.0

 */
