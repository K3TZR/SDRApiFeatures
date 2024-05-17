//
//  File.swift
//  
//
//  Created by Douglas Adams on 5/16/24.
//

import AVFoundation
import Foundation

import RingBufferFeature

// AudioBufferList is protected by TPCircularBuffer logic
extension UnsafeMutablePointer<AudioBufferList> : @unchecked Sendable { }

final public actor RingBuffer{
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ asbd: AudioStreamBasicDescription) {
    self.asbd = asbd
    _TPCircularBufferInit( &buffer, UInt32(RingBuffer.bufferSize), MemoryLayout<TPCircularBuffer>.stride )
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Static properties

  private static let bufferCapacity = 20      // number of AudioBufferLists in the Ring buffer
  private static let bufferOverage = 2_048    // allowance for Ring buffer metadata (in Bytes)
  private static let bufferSize = (RxAudioPlayer.frameCountOpus * MemoryLayout<Float>.size * RxAudioPlayer.channelCount * bufferCapacity) + bufferOverage

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
