//
//  PcmProcessor.swift
//  AudioFeature/PcmProcessor
//
//
//  Created by Douglas Adams on 5/16/24.
//

import AVFoundation
import Foundation

import SharedFeature


//final public actor PcmProcessor {
final public class PcmProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ ringBufferAsbd: AudioStreamBasicDescription, _ ringBuffer: RingBuffer) {
    self.ringBufferAsbd = ringBufferAsbd
    self.ringBuffer = ringBuffer

    // Float32, BigEndian, 2 Channel, interleaved
    interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &interleavedBigEndianAsbd)!, frameCapacity: UInt32(RxAudioPlayer.frameCountPcm * RxAudioPlayer.channelCount))!
    interleavedBuffer.frameLength = interleavedBuffer.frameCapacity

    // Float32, BigEndian, 2 Channel, interleaved
    nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &self.ringBufferAsbd)!, frameCapacity: UInt32(RxAudioPlayer.frameCountPcm * RxAudioPlayer.channelCount))!
    nonInterleavedBuffer.frameLength = nonInterleavedBuffer.frameCapacity

    // PCM, Float32, BigEndian, 2 channel, interleaved -> PCM, Float32, Host, 2 channel, non-interleaved
    interleaveConverter = AVAudioConverter(from: AVAudioFormat(streamDescription: &interleavedBigEndianAsbd)!,
                                           to: AVAudioFormat(streamDescription: &self.ringBufferAsbd)!)!
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  // PCM, Float32, BigEndian, 2 channel, interleaved
  private var interleavedBigEndianAsbd = AudioStreamBasicDescription(mSampleRate: RxAudioPlayer.sampleRate,
                                                                     mFormatID: kAudioFormatLinearPCM,
                                                                     mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian,
                                                                     mBytesPerPacket: UInt32(MemoryLayout<Float>.size * RxAudioPlayer.channelCount),
                                                                     mFramesPerPacket: 1,
                                                                     mBytesPerFrame: UInt32(MemoryLayout<Float>.size * RxAudioPlayer.channelCount),
                                                                     mChannelsPerFrame: UInt32(RxAudioPlayer.channelCount),
                                                                     mBitsPerChannel: UInt32(MemoryLayout<Float>.size * 8),
                                                                     mReserved: 0)

  private var interleavedBuffer: AVAudioPCMBuffer
  private let interleaveConverter: AVAudioConverter
  private var nonInterleavedBuffer: AVAudioPCMBuffer
  private var ringBuffer: RingBuffer
  private var ringBufferAsbd: AudioStreamBasicDescription

  private let oneOverMax: Float = 1.0 / Float(Int16.max)

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func process(_ payload: [UInt8], reducedBandwidth: Bool = false) {
    
    if reducedBandwidth {
      // Reduced Bandwidth - Int16, BigEndian, 1 Channel
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
      memcpy(nonInterleavedBuffer.floatChannelData![0], floatPayload, floatPayload.count * MemoryLayout<Float>.size)
      memcpy(nonInterleavedBuffer.floatChannelData![1], floatPayload, floatPayload.count * MemoryLayout<Float>.size)
      
    } else {
      // Normal Bandwidth - Float, BigEndian, 2 Channel, interleaved
      // copy the data to the buffer
      memcpy(interleavedBuffer.floatChannelData![0], payload, payload.count)
      
      do {
        try interleaveConverter.convert(to: nonInterleavedBuffer, from: interleavedBuffer)
      } catch {
        apiLog.error("PcmProcessor: Interleave conversion error = \(error)")
      }
    }
    // append the data to the Ring buffer
    Task { await self.ringBuffer.enque(nonInterleavedBuffer.mutableAudioBufferList, UInt32(RxAudioPlayer.frameCountPcm))  }
  }
}
