//
//  TcpCommand.swift
//  FlexApiFeature/Tcp
//
//  Created by Douglas Adams on 12/24/21.
//

import CocoaAsyncSocket
import Foundation

import SharedFeature
import XCGLogFeature

// ----------------------------------------------------------------------------
// MARK: - Public structs and enums

public enum TcpStatusType {
  case didConnect
  case didSecure
  case didDisconnect
}

public struct TcpStatus: Identifiable, Equatable {
  public static func == (lhs: TcpStatus, rhs: TcpStatus) -> Bool {
    lhs.id == rhs.id
  }
  
  public init(_ statusType: TcpStatusType, host: String, port: UInt16, error: Error? = nil, reason: String? = nil) {
    self.statusType = statusType
    self.host = host
    self.port = port
    self.error = error
    self.reason = reason
  }
  
  public var id = UUID()
  public var statusType: TcpStatusType = .didDisconnect
  public var host = ""
  public var port: UInt16 = 0
  public var error: Error?
  public var reason: String?
}

public protocol TesterDelegate {
//  @MainActor func testerMessages(_ message: TcpMessage )
  func testerMessages(_ message: TcpMessage )
}

///  Tcp Command Class implementation
///      manages all Tcp communication with a Radio
public final class Tcp: NSObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var testerDelegate: TesterDelegate?
  
  private var _messageStream: (TcpMessage) -> Void = { _ in }
  private var _testerStream: (TcpMessage) -> Void = { _ in }
  private var _statusStream: (TcpStatus) -> Void = { _ in }

  public private(set) var interfaceIpAddress = "0.0.0.0"
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties

  var _isWan: Bool = false
  let _receiveQ = DispatchQueue(label: "TcpCommand.receiveQ")
  var _socket: GCDAsyncSocket!
  var _timeout = 0.0   // seconds
  var _startTime: Date?

  var _sequenceNumber: Int = -1

  // ----------------------------------------------------------------------------
  // MARK: - Initialization (singleton)
  
  public static var shared = Tcp()
  
  /// Initialize a Command Manager
  /// - Parameters:
  ///   - timeout:        connection timeout (seconds)
  private init(timeout: Double = 0.5) {
    _timeout = timeout
    super.init()
    
    // get a socket & set it's parameters
    _socket = GCDAsyncSocket(delegate: self, delegateQueue: _receiveQ)
    _socket.isIPv4PreferredOverIPv6 = true
    _socket.isIPv6Enabled = false
    
    log("Tcp: socket initialized", .debug, #function, #file, #line)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Attempt to connect to a Radio
  /// - Parameters:
  ///   - packet:                 a DiscoveryPacket
  /// - Returns:                  success / failure
  public func connect(_ isWan: Bool, _ requiresHolePunch: Bool, _ holePunchPort: Int, _ publicTlsPort: Int?, _ port: Int, _ publicIp: String, _ localInterfaceIP: String) -> Bool {
    var portToUse = 0
    var localInterface: String?
    var success = true

    _isWan = isWan
    
    // identify the port
    switch (isWan, requiresHolePunch) {
      
    case (true, true):  portToUse = holePunchPort
    case (true, false): portToUse = publicTlsPort!
    default:            portToUse = port
    }
    // attempt a connection
    do {
      if isWan && requiresHolePunch {
        // insure that the localInterfaceIp has been specified
        guard localInterfaceIP != "0.0.0.0" else { return false }
        // create the localInterfaceIp value
        localInterface = localInterfaceIP + ":" + String(portToUse)
        
        // connect via the localInterface
        try _socket.connect(toHost: publicIp, onPort: UInt16(portToUse), viaInterface: localInterface, withTimeout: _timeout)
        log("Tcp: connect on the \(String(describing: localInterface)) interface to \(publicIp) port \(portToUse)", .debug, #function, #file, #line)

      } else {
        // connect on the default interface
        try _socket.connect(toHost: publicIp, onPort: UInt16(portToUse), withTimeout: _timeout)
        log("Tcp: connect on the default interface to \(publicIp) port \(portToUse)", .debug, #function, #file, #line)
      }
      
    } catch _ {
      // connection attemp failed
      log("Tcp: connection failed", .debug, #function, #file, #line)
      success = false
    }
    //        if success { _isWan = packet.isWan ; _seqNum = 0 }
    if success {
      _sequenceNumber = 0
      log("Tcp: connection successful", .debug, #function, #file, #line)
    }
    return success
  }
  
  /// Disconnect TCP from the Radio (hardware)
  public func disconnect() {
    _socket.disconnect()
    _startTime = nil
  }

  
  
  public func performSend(_ cmd: String, diagnostic: Bool = false) async -> UInt  {
    await withCheckedContinuation { continuation in
      continuation.resume(returning: send(cmd, diagnostic: diagnostic) )
    }
  }
  
  
  
  
  
  
  
  
  
  /// Send a Command to the connected Radio
  /// - Parameters:
  ///   - cmd:            a Command string
  ///   - diagnostic:     whether to add "D" suffix
  /// - Returns:          the Sequence Number of the Command
  public func send(_ cmd: String, diagnostic: Bool = false) -> UInt {
    // increment the Sequence Number
    _sequenceNumber += 1
    
    // assemble the command
    let command =  "C" + "\(diagnostic ? "D" : "")" + "\(_sequenceNumber)|" + cmd + "\n"
    
    // send it, no timeout, tag = segNum
    _socket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: -1, tag: _sequenceNumber)
    
    // stream it to the tester (if any)
    if _startTime != nil {
      let timeStamp = Date()
      let message = TcpMessage(text: String(command.dropLast()), direction: .sent, timeStamp: timeStamp, interval: timeStamp.timeIntervalSince(_startTime!))
      _testerStream(message)
    }

    // return the Sequence Number used by this send
    return UInt(_sequenceNumber)
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate

extension Tcp: GCDAsyncSocketDelegate {
  
  /// Receive a command
  /// - Parameters:
  ///   - sock: the connected socket
  ///   - data: the data received
  ///   - tag: the tag on the received data
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // remove the EOL
    if let text = String(data: data, encoding: .ascii)?.dropLast() {
      if _startTime == nil { _startTime = Date() }
      
      // stream it to the Api & tester (if any)
      let timeStamp = Date()
      let message = TcpMessage(text: String(text), direction: .received, timeStamp: timeStamp, interval: timeStamp.timeIntervalSince(_startTime!))
      _messageStream( message )
      _testerStream(message)
    }
    // trigger the next read
    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
  /// TLS did secure
  /// - Parameter sock: the connected socket
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    // TLS connection complete
    _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
    _statusStream( TcpStatus(.didSecure,
                            host: sock.connectedHost ?? "",
                            port: sock.connectedPort,
                            error: nil))
  }
  
  /// TLS did receive trust
  /// - Parameters:
  ///   - sock: the connected socket
  ///   - trust: a SecTrust class
  ///   - completionHandler: a completion handler
  public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
    // no validation required
    log("Tcp: TLS socket did receive trust", .debug, #function, #file, #line)
    completionHandler(true)
  }
  
  /// TCP did disconnect
  /// - Parameters:
  ///   - sock: the connected socket
  ///   - err: an error (if any)
  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    _statusStream( TcpStatus(.didDisconnect, host: "", port: 0, error: err) )
  }
  
  /// TCP did connect
  /// - Parameters:
  ///   - sock: the socket
  ///   - host: the host
  ///   - port: the port
  public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
    // Connected
    interfaceIpAddress = host
    
    // is this a Wan connection?
    if _isWan {
      // YES, secure the connection using TLS
      sock.startTLS( [GCDAsyncSocketManuallyEvaluateTrust : 1 as NSObject] )

    } else {
      // NO, we're connected
      _statusStream( TcpStatus(.didConnect, host: host, port: port, error: nil) )
      // trigger the next read
      _socket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Stream definitions

extension Tcp {
  
  /// A stream of received TCP Messages
  public var messageStream: AsyncStream<TcpMessage> {
    AsyncStream { continuation in
      _messageStream = { tcpMessage in
        continuation.yield(tcpMessage)
      }
      continuation.onTermination = { @Sendable _ in
      }
    }
  }
  
  /// A stream of received & sent TCP Messages
  public var testerStream: AsyncStream<TcpMessage> {
    AsyncStream { continuation in
      _testerStream = { tcpMessage in
        continuation.yield(tcpMessage)
      }
      continuation.onTermination = { @Sendable _ in
      }
    }
  }
  
  /// A stream of Tcp Status changes
  public var statusStream: AsyncStream<TcpStatus> {
    AsyncStream { continuation in
      _statusStream = { status in
        continuation.yield(status)
      }
      continuation.onTermination = { @Sendable _ in
      }
    }
  }
}
