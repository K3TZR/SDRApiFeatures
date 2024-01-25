//
//  LocalListener.swift
//  FlexApiFeature/Listener
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import Combine

import SharedFeature
import VitaFeature
import XCGLogFeature

public enum LanListenerError: Error {
  case kSocketError
  case kReceivingError
}

/// Listener implementation
///
///      listens for the udp broadcasts announcing the presence
///      of a Flex-6000 Radio, publishes changes
///
public final class LocalListener: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _cancel: Task<(), Never>?
  private var _cancellables = Set<AnyCancellable>()
  private let _formatter = DateFormatter()
  private var _ignoreTimeStamps = false
  private let _listenerModel: ListenerModel!
  private var _logBroadcasts = false
  private let _udpQ = DispatchQueue(label: "LanListener" + ".udpQ")
  private var _udpSocket: GCDAsyncUdpSocket!
  
  
  var currentBytes = [UInt8](repeating: 0x00, count: 560)
  var previousBytes = [UInt8](repeating: 0x00, count: 560)
  
  var currentPayload: String = ""
  var previousPayload: String = ""
  
  var currentNullCount = 0
  
  static let broadcastTimeout = 20.0
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(_ listenerModel: ListenerModel, port: UInt16 = 4992, logBroadcasts: Bool = false, ignoreTimeStamps: Bool = false) {
    _listenerModel = listenerModel
    _logBroadcasts = logBroadcasts
    _ignoreTimeStamps = ignoreTimeStamps
    super.init()
    
    _formatter.timeZone = .current
    _formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    
    // create a Udp socket and set options
    _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    try! _udpSocket.enableReusePort(true)
    try! _udpSocket.bind(toPort: port)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func start(checkInterval: TimeInterval = 1.0, timeout: TimeInterval = broadcastTimeout) {
    try! _udpSocket.beginReceiving()
    log("Local Listener: STARTED", .info, #function, #file, #line)

    // setup a timer to watch for Radio timeouts
    Timer.publish(every: checkInterval, on: .main, in: .default)
      .autoconnect()
      .sink { now in
        Task {
          await MainActor.run {
            self._listenerModel.removePackets(condition: { $0.source == .local && abs($0.lastSeen.timeIntervalSince(now)) > timeout } )
          }
        }
      }
      .store(in: &_cancellables)
  }
  /// stop the listener
  func stop() {
    _cancellables = Set<AnyCancellable>()
    _udpSocket?.close()
    log("Local Listener: STOPPED", .info, #function, #file, #line)
  }
  
//  func start(checkInterval: TimeInterval = 1.0, timeout: TimeInterval = 10.0) {
//    try! _udpSocket.beginReceiving()
//    log("Lan Listener: STARTED", .info, #function, #file, #line)
//
//    // setup a timer to watch for Radio timeouts
//    _cancel = Task {
//      repeat {
//        self._listener.removePackets(condition: { $0.source == .local && abs($0.lastSeen.timeIntervalSince(Date())) > timeout } )
//        try? await Task.sleep(for: .seconds(checkInterval))
//      }while (!Task.isCancelled)
//    }
//  }
//  /// stop the listener
//  func stop() {
//    _cancel = nil
//    _udpSocket?.close()
//    log("Lan Listener: STOPPED", .info, #function, #file, #line)
//  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncUdpSocketDelegate extension

extension LocalListener: GCDAsyncUdpSocketDelegate {
  /// The Socket received data
  ///
  /// - Parameters:
  ///   - sock:           the GCDAsyncUdpSocket
  ///   - data:           the Data received
  ///   - address:        the Address of the sender
  ///   - filterContext:  the FilterContext
  public func udpSocket(_ sock: GCDAsyncUdpSocket,
                        didReceive data: Data,
                        fromAddress address: Data,
                        withFilterContext filterContext: Any?) {
    
    if _logBroadcasts { checkBroadcastBytes(data, address) }
    
    // VITA packet?
    guard let vita = Vita.decode(from: data) else { return }
    
    // YES, Discovery Packet?
    guard let packet = parseDiscovery(vita) else { return }
    
    // YES, process it
    Task {
      await MainActor.run {
        _listenerModel.processPacket(packet)
      }
    }
  }
  
  /// Parse a Vita class containing a Discovery broadcast
  /// - Parameter vita:   a Vita packet
  /// - Returns:          a DiscoveryPacket (or nil)
  private func parseDiscovery(_ vita: Vita) -> Packet? {
    // is this a Discovery packet?
    if vita.classIdPresent && vita.classCode == .discovery {
      // Payload is a series of strings of the form <key=value> separated by ' ' (space)
      var payloadData = NSString(bytes: vita.payloadData, length: vita.payloadSize, encoding: String.Encoding.utf8.rawValue)! as String
      
      if _logBroadcasts { checkPayload(payloadData) }
      
      // eliminate any Nulls at the end of the payload
      payloadData = payloadData.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
      
      if _logBroadcasts { checkPayloadNulls(payloadData) }
      
//      return Packet.populate( payloadData.keyValuesArray() )
      let packet = Packet.populate( payloadData.keyValuesArray() )

//      for guiClient in packet.guiClients {
//        _listener.guiClients[id: guiClient.id] = guiClient
//      }
      return packet
    }
    return nil
  }
}

extension  LocalListener {
  // ----------------------------------------------------------------------------
  // MARK: - Debugging tools extension
  
  public func checkBroadcastBytes(_ data: Data, _ address: Data) {
    (data as NSData).getBytes(&currentBytes, range: NSMakeRange(0, 551))
    
    if _ignoreTimeStamps {
      currentBytes[1] = UInt8(0)
      currentBytes[16] = UInt8(0)
      currentBytes[17] = UInt8(0)
      currentBytes[18] = UInt8(0)
      currentBytes[19] = UInt8(0)
      currentBytes[20] = UInt8(0)
      currentBytes[21] = UInt8(0)
      currentBytes[22] = UInt8(0)
      currentBytes[23] = UInt8(0)
      currentBytes[24] = UInt8(0)
      currentBytes[25] = UInt8(0)
      currentBytes[26] = UInt8(0)
      currentBytes[27] = UInt8(0)
    }
    
    //      var addressString = ""
    //      (address as NSData).getBytes(&addressString, range: NSMakeRange(0, 199))
    //      print("Address = \(addressString)")
    
    if currentBytes.count == previousBytes.count {
      if currentBytes != previousBytes {
        print(hexDump(data))
      }
    } else {
      print(hexDump(data))
    }
    previousBytes = currentBytes
  }
  
  public func checkPayload(_ payloadData: String) {
    currentPayload = payloadData
    if currentPayload != previousPayload {
      print("payload = \(payloadData)")
      previousPayload = currentPayload
    }
  }
  
  public func checkPayloadNulls(_ payloadData: String) {
    currentNullCount = previousPayload.count - payloadData.count
    if currentNullCount > 0 {
      print("\(currentNullCount) nulls removed from Payload")
    }
  }
  
  /// Create a String representing a Hex Dump of a UInt8 array
  ///
  /// - Parameters:
  ///   - data:           an array of UInt8
  ///   - len:            the number of elements to be processed
  /// - Returns:          a String
  ///
  public func hexDump(rawData: Data, address: Data, count: Int, data: [UInt8], len: Int) -> String {
    
    print("\nAddress: \(address as NSData))")
    print("Data:    \(rawData as NSData))\n")
    
    var string = "  \(String(format: "%3d", count))    00 01 02 03 04 05 06 07   08 09 0A 0B 0C 0D 0E 0F\n"
    string += " bytes    -------------------------------------------------\n\n"
    
    var address = 0
    string += address.toHex() + "   "
    for i in 1...len {
      string += String(format: "%02X", data[i-1]) + " "
      if (i % 8) == 0 { string += "  " }
      if (i % 16) == 0 {
        string += "\n"
        address += 16
        string += address.toHex() + "   "
      }
    }
    string += "\n         -------------------------------------------------\n\n"
    return string
  }
  
  
  
  public func hexDump(_ data: Data) -> String {
    let len = 552
    var bytes = [UInt8](repeating: 0x00, count: len)

    (data as NSData).getBytes(&bytes, range: NSMakeRange(0, len))
    
    var string = "  \(String(format: "%3d", len + 1))    00 01 02 03 04 05 06 07   08 09 0A 0B 0C 0D 0E 0F\n"
    string += " bytes    -------------------------------------------------\n\n"
    
    string += "----- HEADER -----\n"
    
    var address = 0
    string += address.toHex() + "   "
    for i in 1...28 {
      string += String(format: "%02X", bytes[i-1]) + " "
      if (i % 8) == 0 { string += "  " }
      if (i % 16) == 0 {
        string += "\n"
        address += 16
        string += address.toHex() + "   "
      }
    }

    string += "\n\n----- PAYLOAD -----\n"
      
    
    string += address.toHex() + "                                         "
    for i in 29...len {
      string += String(format: "%02X", bytes[i-1]) + " "
      if (i % 8) == 0 { string += "  " }
      if (i % 16) == 0 {
        string += "\n"
        address += 16
        string += address.toHex() + "   "
      }
    }

    string += "\n\n----- PAYLOAD -----\n"
      
    
    string += address.toHex() + "                                         "
    for i in 29...len {
      string += String(decoding: bytes[i-1...i-1], as: UTF8.self) + "  "
      if (i % 8) == 0 { string += "  " }
      if (i % 16) == 0 {
        string += "\n"
        address += 16
        string += address.toHex() + "   "
      }
    }
    
    
    string += "\n\n----- PAYLOAD -----\n"
      

    let payloadBytes = bytes[27...len-1]
    let text = String(decoding: payloadBytes, as: UTF8.self)
    let lines = text.components(separatedBy: " ")
    let newText = lines.reduce("") {$0 + "<\($1)>\n"}
    string += newText
    
    
    string += "\n         -------------------------------------------------\n\n"
    return string
  }
}
