//
//  OpusProcessor.swift
//  
//
//  Created by Douglas Adams on 5/16/24.
//

import AVFoundation
import Foundation

import SharedFeature
import XCGLogFeature

final public actor OpusProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ ringBufferAsbd: AudioStreamBasicDescription, _ ringBuffer: RingBuffer) {
    self.ringBufferAsbd = ringBufferAsbd
    self.ringBuffer = ringBuffer
    
    // ----- Buffers -----
    // OPUS Float32, Host, 2 Channel, non-interleaved
    opusBuffer = AVAudioCompressedBuffer(format: AVAudioFormat(streamDescription: &self.asbd)!, packetCapacity: 1, maximumPacketSize: RxAudioPlayer.frameCountOpus)
    
    // PCM Float32, Host, 2 Channel, interleaved
    interleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &self.interleavedAsbd)!, frameCapacity: UInt32(RxAudioPlayer.frameCountOpus))!
    interleavedBuffer.frameLength = interleavedBuffer.frameCapacity

    // PCM Float32, Host, 2 Channel, non-interleaved
    nonInterleavedBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &self.ringBufferAsbd)!, frameCapacity: UInt32(RxAudioPlayer.frameCountOpus * RxAudioPlayer.channelCount))!
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
  // MARK: - Private properties
  
  // Opus, UInt8, 2 channel (buffer used to store incoming Opus encoded samples)
  private var asbd = AudioStreamBasicDescription(mSampleRate: RxAudioPlayer.sampleRate,
                                                 mFormatID: kAudioFormatOpus,
                                                 mFormatFlags: 0,
                                                 mBytesPerPacket: 0,
                                                 mFramesPerPacket: UInt32(RxAudioPlayer.frameCountOpus),
                                                 mBytesPerFrame: 0,
                                                 mChannelsPerFrame: UInt32(RxAudioPlayer.channelCount),
                                                 mBitsPerChannel: 0,
                                                 mReserved: 0)
  
  // PCM, Float32, Host, 2 channel, interleaved
  private var interleavedAsbd = AudioStreamBasicDescription(mSampleRate: RxAudioPlayer.sampleRate,
                                                            mFormatID: kAudioFormatLinearPCM,
                                                            mFormatFlags: kAudioFormatFlagIsFloat,
                                                            mBytesPerPacket: UInt32(MemoryLayout<Float>.size * RxAudioPlayer.channelCount),
                                                            mFramesPerPacket: 1,
                                                            mBytesPerFrame: UInt32(MemoryLayout<Float>.size * RxAudioPlayer.channelCount),
                                                            mChannelsPerFrame: UInt32(RxAudioPlayer.channelCount),
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
    if error != nil { log("OpusProcessor: Opus conversion error: \(error!)", .error, #function, #file, #line) }
    
    do {
      try interleaveConverter.convert(to: nonInterleavedBuffer, from: interleavedBuffer)
      // append the data to the Ring buffer
      Task { await self.ringBuffer.enque(nonInterleavedBuffer.mutableAudioBufferList, UInt32(RxAudioPlayer.frameCountOpus))  }
    } catch {
      log("OpusProcessor: Interleave conversion error = \(error)", .error, #function, #file, #line)
    }
  }
}
