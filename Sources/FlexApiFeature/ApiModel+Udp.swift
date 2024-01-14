//
//  ApiModel+Udp.swift
//  
//
//  Created by Douglas Adams on 5/25/23.
//

import SharedFeature
import UdpFeature


extension ApiModel {
  private func udpStatus(_ status: UdpStatus) {
    switch status.statusType {
      
    case .didUnBind:
      log("ApiModel: Udp unbound from port, \(status.receivePort)", .debug, #function, #file, #line)
    case .failedToBind:
      log("ApiModel: Udp failed to bind, " + (status.error?.localizedDescription ?? "unknown error"), .warning, #function, #file, #line)
    case .readError:
      log("ApiModel: Udp read error, " + (status.error?.localizedDescription ?? "unknown error"), .warning, #function, #file, #line)
    }
  }
  
  // Process the AsyncStream of UDP status changes
  private func subscribeToUdpStatus() {
    Task(priority: .high) {
      log("ApiModel: UdpStatus subscription STARTED", .debug, #function, #file, #line)
      for await status in Udp.shared.statusStream {
        udpStatus(status)
      }
      log("ApiModel: UdpStatus subscription STOPPED", .debug, #function, #file, #line)
    }
  }
}
