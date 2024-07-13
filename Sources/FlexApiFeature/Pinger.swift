//
//  Pinger.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 12/14/16.
//  Copyright © 2018 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation
import SwiftUI

///  Pinger  implementation
///
///      generates "ping" messages every pingInterval second(s)
///
public final class Pinger {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(pingInterval: Int = 1, pingTimeout: Double = 10, _ objectModel: ObjectModel) {
    _lastPingRxTime = Date(timeIntervalSinceNow: 0)
    _objectModel = objectModel
    startPinging(interval: pingInterval, timeout: pingTimeout)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _lastPingRxTime: Date!
  private var _objectModel: ObjectModel
  private let _pingQ = DispatchQueue(label: "PingQ")
  private var _pingTimer: DispatchSourceTimer!
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func stopPinging() {
    _pingTimer?.cancel()
  }
  
  public func pingReplyHandler(_ command: String, _ reply: String) {
    _lastPingRxTime = Date()
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func startPinging(interval: Int, timeout: Double) {
    // create the timer's dispatch source
    _pingTimer = DispatchSource.makeTimerSource(queue: _pingQ)
    
    // Setup the timer
    _pingTimer.schedule(deadline: DispatchTime.now(), repeating: .seconds(interval))
    
    // set the event handler
    _pingTimer.setEventHandler(handler: { [self] in
      // has it been too long since the last response?
      let interval = Date().timeIntervalSince(_lastPingRxTime)
      if interval > timeout {
        // YES, stop the Pinger
        stopPinging()
        
      } else {
        Task { await MainActor.run {
          _objectModel.sendTcp("ping", replyTo: self.pingReplyHandler)
        }}
      }
    })
    // start the timer
    _pingTimer.resume()
  }
}
