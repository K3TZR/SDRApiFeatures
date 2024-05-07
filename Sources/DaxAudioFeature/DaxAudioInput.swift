//
//  DaxAudioInput.swift
//
//
//  Created by Douglas Adams on 4/13/24.
//

import Accelerate
import AVFoundation

import FlexApiFeature
import RingBufferFeature
import SharedFeature
import XCGLogFeature

@Observable
final public class DaxAudioInput: Equatable, DaxAudioInputHandler {
  public static func == (lhs: DaxAudioInput, rhs: DaxAudioInput) -> Bool {
    lhs === rhs
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var active = false
  public var streamId: UInt32?
  public var deviceId: AudioDeviceID
  public var gain: Double
  public var sampleRate: Double
  
  public var levels = SignalLevel(rms: -50,peak: -50)
  public var status = "Off"
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _engine = AVAudioEngine()
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(deviceId: AudioDeviceID, gain: Double, sampleRate: Int = 24_000) {
    self.deviceId = deviceId
    self.gain = gain
    self.sampleRate = Double(sampleRate)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start() {
    print("Start")
    
    guard streamId != nil else { fatalError("StreamId is nil")}
    let id = streamId!
    
    active = true
    // Get the native audio format of the engine's input bus
    let inputFormat = _engine.inputNode.inputFormat(forBus: 0)
    
    // Set an output format
    let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 24_000, channels: 1)
    
    let mixerNode = AVAudioMixerNode()
    // Attach a mixer node to convert the input
    _engine.attach(mixerNode)
    
    // Attach the mixer to the microphone input
    _engine.connect(_engine.inputNode, to: mixerNode, format: inputFormat)
    //  audioEngine.connect(mixerNode, to: audioEngine.outputNode, format: outputFormat)
    _engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) {(buffer, time) in
      
//      print(time, buffer)
      
      StreamModel.shared.daxTxAudioStreams[id:id]?.send(buffer)
    }
    
    _engine.prepare()
    try! _engine.start()
  }
  
  public func stop() {
    active = false
    _engine.mainMixerNode.removeTap(onBus: 0)
    _engine.stop()
    Task {
      await MainActor.run {
        levels = SignalLevel(rms: -50,peak: -50)
      }
    }
  }
  
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
//    self.gain = gain
    if let streamId = streamId {
      Task {
        if let sliceLetter = StreamModel.shared.daxRxAudioStreams[id: streamId]?.sliceLetter {
          for slice in await ObjectModel.shared.slices where await slice.sliceLetter == sliceLetter {
            if StreamModel.shared.daxRxAudioStreams[id: streamId]?.clientHandle == ApiModel.shared.connectionHandle {
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

  public func daxAudioInputHandler(payload: [UInt8], reducedBW: Bool) {
    //
  }
  

  // ----------------------------------------------------------------------------
  // MARK: - Stream reply handler
  
  public func streamReplyHandler(_ command: String, _ seqNumber: Int, _ responseValue: String, _ reply: String) {
    if reply != kNoError {
      if let streamId = reply.streamId {
        self.streamId = streamId
        
        start()
        Task {
          await MainActor.run { StreamModel.shared.daxTxAudioStreams[id: streamId]?.delegate = self }
        }
        log.debug("DaxAudioInput: input STARTED, Stream Id = \(streamId.hex)")
      }
    }
  }
}

//
//  // ----------------------------------------------------------------------------
//  // MARK: - Stream Handler protocol method
//  
//  public func daxAudioHandler(payload: [UInt8], reducedBW: Bool = false) {
//    let oneOverMax: Float = 1.0 / Float(Int16.max)
//    
//    if reducedBW {
//      // Reduced Bandwidth - Int16, BigEndian, 1 Channel
//      // allocate temporary array
//      var floatPayload = [Float](repeating: 0, count: payload.count / MemoryLayout<Int16>.size)
//      
//      payload.withUnsafeBytes { (payloadPtr) in
//        // Int16 Mono Samples
//        // get a pointer to the data in the payload
//        let uint16Ptr = payloadPtr.bindMemory(to: UInt16.self)
//        
//        for i in 0..<payload.count / MemoryLayout<Int16>.size {
//          let uintVal = CFSwapInt16BigToHost(uint16Ptr[i])
//          // convert to Float
//          let floatVal = Float(Int16(bitPattern: uintVal)) * oneOverMax
//          // populate non-interleaved array of Float32
//          floatPayload[i] = floatVal
//        }
//      }
//      
//      // reduced BW is mono, copy same data to Left & right channels
//      memcpy(_nonInterleavedBuffer.floatChannelData![0], floatPayload, floatPayload.count * MemoryLayout<Float>.size)
//      memcpy(_nonInterleavedBuffer.floatChannelData![1], floatPayload, floatPayload.count * MemoryLayout<Float>.size)
//      
//      // append the data to the Ring buffer
//      TPCircularBufferCopyAudioBufferList(&_ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(_frameCount), &_nonInterleavedASBD)
//      
//    } else {
//      // Full Bandwidth - Float32, BigEndian, 2 Channel, interleaved
//      // copy the data to the buffer
//      memcpy(_interleavedBuffer.floatChannelData![0], payload, payload.count)
//      
//      // convert Float32, BigEndian, 2 Channel, interleaved -> Float32, BigEndian, 2 Channel, non-interleaved
//      do {
//        try _converter.convert(to: _nonInterleavedBuffer, from: _interleavedBuffer)
//        // append the data to the Ring buffer
//        TPCircularBufferCopyAudioBufferList(&_ringBuffer, &_nonInterleavedBuffer.mutableAudioBufferList.pointee, nil, UInt32(_frameCount), &_nonInterleavedASBD)
//        
//      } catch {
//        fatalError("DaxAudioPlayer: Conversion error = \(error)")
//      }
//    }
//  }
//}
