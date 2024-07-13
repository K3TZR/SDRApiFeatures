//
//  RemoteRxAudioStream.swift
//
//
//  Created by Douglas Adams on 7/8/24.
//

import Foundation

import AudioFeature
import SharedFeature
import VitaFeature

final public class RemoteRxAudioStream: StreamProcessor {
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init() {}

  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var rxAudioOutput: RxAudioPlayer?

  // ------------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func start(_ streamId: UInt32)  {
    rxAudioOutput = RxAudioPlayer(streamId)
    rxAudioOutput!.start()
  }
  
  public func stop()  {
    rxAudioOutput?.stop()
    if let streamId = rxAudioOutput?.streamId {
      Task { await MainActor.run {
        ObjectModel.shared.sendTcp("stream remove \(streamId.hex)")
      }}
    }
    rxAudioOutput = nil
  }

  public func streamProcessor(_ vita: Vita) {
    //
    rxAudioOutput!.audioProcessor(vita)
  }
}
