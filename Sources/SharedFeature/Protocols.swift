//
//  Protocols.swift
//  SharedFeatures/Shared
//
//  Created by Douglas Adams on 11/29/22.
//

import Foundation

/// UDP Stream handler protocol
public protocol StreamHandler: AnyObject {
  /// Process a frame of Stream data
  /// - Parameter frame:        a frame of data
  func streamHandler<T>(_ frame: T)
}

/// UDP AudioStream handler protocol
public protocol AudioStreamHandler: AnyObject {
  /// Process a frame of Audio data
  /// - Parameters:
  ///   - buffer: the data
  ///   - samples: sample count
  func sendAudio(buffer: [UInt8], samples: Int)
}



/// UDP Stream handler protocol
public protocol RxAudioHandler: AnyObject {
  /// Process Stream data
  /// - Parameters:
  ///   - payload: array of bytes
  ///   - compressed: is compressed
  func rxAudioHandler(payload: [UInt8],
                      compressed: Bool)
}

/// UDP Stream handler protocol
public protocol DaxRxAudioHandler: AnyObject {
  /// Process Stream data
  /// - Parameters:
  ///   - payload: array of bytes
  ///   - reducedBW: Float32(false) vs Int16(true) element size
  ///   - channelNumber: dax channel number
  func daxRxAudioHandler(payload: [UInt8],
                         reducedBW: Bool,
                         channelNumber: Int?)
  
}
