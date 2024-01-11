//
//  Pinger.swift
//  ApiFeatures/Objects
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
  
  public init(pingInterval: Int = 1, pingTimeout: Double = 10, initializationCount: Int = 2, _ apiModel: ApiModel) {
    _lastPingRxTime = Date(timeIntervalSinceNow: 0)
    _initializationCount = initializationCount
    _apiModel = apiModel
    startPinging(interval: pingInterval, timeout: pingTimeout)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _apiModel: ApiModel
  
  private var _initializationCount = 0
  private var _lastPingRxTime: Date!
  private var _pingCount = 0
  private let _pingQ = DispatchQueue(label: "PingQ")
  private var _pingTimer: DispatchSourceTimer!
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func stopPinging() {
    _pingTimer?.cancel()
  }
  
  public func pingReply(_ command: String, seqNum: UInt, responseValue: String, reply: String) {
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
        Task(priority: .low) {
          await MainActor.run { _apiModel.sendCommand("ping", replyTo: self.pingReply) }
          if _pingCount < _initializationCount {
            _pingCount += 1
          } else if _pingCount == _initializationCount {
            await MainActor.run { _apiModel.nthPingReceived = true }
          }
        }
      }
    }
    )
    // start the timer
    _pingTimer.resume()
  }
}
