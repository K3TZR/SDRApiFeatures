//
//  SmartlinkListener.swift
//  ApiFeatures/Listener
//
//  Created by Douglas Adams on 12/5/21.
//

import Foundation
import CocoaAsyncSocket
import Combine

import SharedFeature
import XCGLogFeature

public enum ListenerError: String, Error {
  case wanConnect = "WanConnect Failed"
  case wanValidation = "WanValidation Failed"
}

///  WanListener Class implementation
///      connect to the Smartlink server which announces the presence
///      of Smartlink-accessible Radio(s), publishes changes

public final class SmartlinkListener: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public static let kTimeout: Double = 5.0
    
  // ----------------------------------------------------------------------------
  // MARK: - Internal properties
  
  var _tcpSocket: GCDAsyncSocket!
  var _callsign: String?
  var _firstName: String?
  var _host: String?
  var _lastName: String?
  var _serial: String?
  var _wanHandle: String?
  var _publicIp: String?

  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private var _appName: String?
  private var _authentication = Authentication()
  private var _cancellables = Set<AnyCancellable>()
  private var _domain: String?
  private var _idToken: IdToken? = nil
  private let _pingQ = DispatchQueue(label: "WanListener.pingQ")
  private var _platform: String?
  private var _previousIdToken: IdToken?
  private var _pwd: String?
  private let _socketQ = DispatchQueue(label: "WanListener.socketQ")
  private var _timeout = 0.0                // seconds
  private var _user: String?
  
  private let kSmartlinkHost = "smartlink.flexradio.com"
  private let kSmartlinkPort: UInt16 = 443
  private let kPlatform = "macOS"
  
  
  let _listener: Listener!
  
  
  var awaitWanHandle: CheckedContinuation<String, Error>?

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(_ listener: Listener, timeout: Double = kTimeout) {
    _listener = listener

    super.init()

    _appName = (Bundle.main.infoDictionary!["CFBundleName"] as! String)
    _timeout = timeout

    // get a socket & set it's parameters
    _tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: _socketQ)
    _tcpSocket.isIPv4PreferredOverIPv6 = true
    _tcpSocket.isIPv6Enabled = false
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Internal methods
    
//  func forceLogin() {
//    _authentication.forceLogin()
//  }
  
  func start(_ user: String, _ requireLogin: Bool = false) async -> Bool {
    if requireLogin || user.isEmpty {
      _authentication.deleteTokens()
      return false
    }
    if let idToken = await _authentication.authenticate(user) {
      return start(using: idToken)
    }
    return false
  }
  
  /// Start listening given a User / Pwd
  /// - Parameters:
  ///   - user:           user value
  ///   - pwd:            user password
  func start(user: String, pwd: String) async -> Bool {
    let idToken = await _authentication.requestTokens(user: user, pwd: pwd)
    
    print("Start: idToken = \(idToken ?? "nil")")
    
    if idToken != nil {
      _previousIdToken = idToken
      log("Wan Listener: IdToken obtained from login credentials", .debug, #function, #file, #line)
      if start(using: idToken!) { return true }
    }
    return false
  }
  
  /// stop the listener
  func stop() {
    _cancellables.removeAll()
    _tcpSocket.disconnect()
    log("Wan Listener: STOPPED", .info, #function, #file, #line)
  }
  /// Send a command to the server using TLS
  /// - Parameter cmd:                command text
  func sendTlsCommand(_ cmd: String, timeout: TimeInterval = kTimeout, tag: Int = 1) {
    // send the specified command to the SmartLink server using TLS
    let command = cmd + "\n"
    _tcpSocket.write(command.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withTimeout: timeout, tag: 0)
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Start listening given an IdToken
  /// - Parameters:
  ///   - idToken:           a valid IdToken
  private func start(using idToken: IdToken) -> Bool {
    _previousIdToken = idToken
    // use the ID Token to connect to the Smartlink service
    do {
      try connect(using: idToken)
      return true
    } catch {
      return false
    }
  }

  /// Initiate a connection to the Smartlink server
  /// - Parameters:
  ///   - idToken:        an ID Token
  ///   - timeout:        timeout (seconds)
  private func connect(using idToken: IdToken) throws {
    _idToken = idToken    // used later by socketDidSecure
    
    // try to connect
    do {
      try _tcpSocket.connect(toHost: kSmartlinkHost, onPort: kSmartlinkPort, withTimeout: _timeout)
      log("Wan Listener: TCP Socket connection initiated", .debug, #function, #file, #line)
      
    } catch _ {
      throw WanListenerError.kFailedToConnect
    }
  }
  
  /// Ping the SmartLink server
  private func startPinging() {
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: 10, on: .main, in: .default)
      .autoconnect()
      .sink { _ in
        // send another Ping
        self.sendTlsCommand("ping from client", timeout: -1)
      }
      .store(in: &_cancellables)
    log("Wan Listener: STARTED pinging \(_host ?? "????")", .debug, #function, #file, #line)
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncSocketDelegate extension

extension SmartlinkListener: GCDAsyncSocketDelegate {
  //      All are called on the _socketQ
  //
  //      1. A TCP connection is opened to the SmartLink server
  //      2. A TLS connection is then initiated over the TCP connection
  //      3. The TLS connection "secures" and is now ready for use
  //
  //      If a TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
  //      and the socketDidDisconnect:withError: delegate method will be called with an error code.
  //
  public func socket(_ sock: GCDAsyncSocket,
                     didConnectToHost host: String,
                     port: UInt16) {
    _host = host
    log("Wan Listener: TCP Socket didConnectToHost, \(host):\(port)", .debug, #function, #file, #line)
    
    // initiate a secure (TLS) connection to the Smartlink server
    var tlsSettings = [String : NSObject]()
    tlsSettings[kCFStreamSSLPeerName as String] = kSmartlinkHost as NSObject
    _tcpSocket.startTLS(tlsSettings)
    
    log("Wan Listener: TLS Socket connection initiated", .debug, #function, #file, #line)
  }
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    log("Wan Listener: TLS socketDidSecure", .debug, #function, #file, #line)
    
    // start pinging SmartLink server
    startPinging()
    
    // register the Application / token pair with the SmartLink server
    sendTlsCommand("application register name=\(_appName!) platform=\(kPlatform) token=\(_idToken!)", timeout: _timeout, tag: 0)
    log("Wan Listener: Application registered, name=\(_appName!) platform=\(kPlatform)", .debug, #function, #file, #line)

    // start reading
    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
    log("Wan Listener: STARTED", .info, #function, #file, #line)
  }
  
  public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
    // get the bytes that were read
    if let msg = String(data: data, encoding: .ascii) {
      // process the message
      parseVitaPayload(msg)
    }
    // trigger the next read
    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
  }
  
  public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
    // Disconnected from the Smartlink server
    let error = (err == nil ? "" : " with error: " + err!.localizedDescription)
    log("Wan Listener: TCP socketDidDisconnect \(error)",
         err == nil ? .debug : .warning, #function, #file, #line)
    if err != nil { stop() }
  }
  
  public func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
    return 0
  }
  
  public func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
    return 30.0
  }
}
