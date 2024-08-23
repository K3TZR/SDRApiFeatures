//
//  Logging.swift
//
//
//  Created by Douglas Adams on 6/27/24.
//

import Foundation
import os

public let log = ApiLog()

public struct ApiLog {
  
  private let apiLog = Logger(subsystem: "net.k3tzr.sdrApiFeatures", category: "FlexApiFeature")
  
  init() {}
  
  public func debug(_ message: String) {
    apiLog.debug("\(message)")
  }
  public func info(_ message: String) {
    apiLog.info("\(message)")
  }
  public func warning(_ message: String) {
    apiLog.warning("\(message)")
    NotificationCenter.default.post(name: Notification.Name.logAlertWarning, object: message)
  }
  public func error(_ message: String) {
    apiLog.error("\(message)")
    NotificationCenter.default.post(name: Notification.Name.logAlertError, object: message)
  }
}

extension Notification.Name {
  public static let logAlertWarning = Notification.Name("LogAlertWarning")
  public static let logAlertError = Notification.Name("logAlertError")
}

