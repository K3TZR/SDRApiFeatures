//
//  SmartlinkListener.swift
//  FlexApiFeature/Listener
//
//  Created by Douglas Adams on 12/5/21.
//

import Foundation
import CocoaAsyncSocket
import Combine

import SharedFeature
//import XCGLogFeature

public enum ListenerError: String, Error {
  case wanConnect = "WanConnect Failed"
  case wanValidation = "WanValidation Failed"
}

public struct Tokens {
  public var idToken: String
  public var refreshToken: String
  
  public init(_ idToken: String, _ refreshToken: String) {
    self.idToken = idToken
    self.refreshToken = refreshToken
  }
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
  private var _currentTokens = Tokens("", "")
  private var _domain: String?
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
  
  
  let _listenerModel: ListenerModel!
  
  
  var awaitWanHandle: CheckedContinuation<String, Error>?

  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(_ listenerModel: ListenerModel, timeout: Double = kTimeout) {
    _listenerModel = listenerModel

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
    
  func start(_ currentTokens: Tokens) async -> Tokens {
//    if let previousIdToken {
//      log("Smartlink Listener: Previous idToken found", .debug, #function, #file, #line)
//      return start(using: previousIdToken)
//      
//    } else 
    let validatedTokens = await _authentication.authenticate(currentTokens)
    if !validatedTokens.idToken.isEmpty {
      apiLog.debug("Smartlink Listener: idToken found using authenticate")
      return connect(using: validatedTokens)
      
    } else {
      apiLog.debug("Smartlink Listener: idToken NOT found")
    }
    return Tokens("", "")
  }
  
  /// Start listening given a User / Pwd
  /// - Parameters:
  ///   - user:           user value
  ///   - pwd:            user password
  func start(user: String, pwd: String) async -> Tokens {
    let tokens = await _authentication.requestTokens(user: user, pwd: pwd)
    if !tokens.idToken.isEmpty {
      //      _previousIdToken = idToken
      apiLog.debug("Smartlink Listener: IdToken obtained from login credentials")
      return connect(using: tokens)
    }
    return Tokens("", "")
  }
  
  /// stop the listener
  func stop() {
    _cancellables.removeAll()
    _tcpSocket.disconnect()
    apiLog.info("Smartlink Listener: STOPPED")
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
//  private func start(using idToken: IdToken) -> String? {
//    SettingsModel.shared.previousIdToken = idToken
    // use the ID Token to connect to the Smartlink service
//    do {
//      try connect(using: idToken)
//      return idToken
//    } catch {
//      log("Smartlink Listener: TCP Socket connection FAILED", .debug, #function, #file, #line)
//      return nil
//    }
//  }
  private func connect(using tokens: Tokens) -> Tokens {
    _currentTokens = tokens
    // use the ID Token to connect to the Smartlink service
    do {
      try _tcpSocket.connect(toHost: kSmartlinkHost, onPort: kSmartlinkPort, withTimeout: _timeout)
      apiLog.debug("Smartlink Listener: TCP Socket connection initiated")
      return tokens

    } catch {
      apiLog.debug("Smartlink Listener: TCP Socket connection FAILED")
      return Tokens("", "")
    }
  }

  /// Initiate a connection to the Smartlink server
  /// - Parameters:
  ///   - idToken:        an ID Token
  ///   - timeout:        timeout (seconds)
//  private func connect(using idToken: IdToken) throws {
//    _currentIdToken = idToken
//    // try to connect
//    do {
//      try _tcpSocket.connect(toHost: kSmartlinkHost, onPort: kSmartlinkPort, withTimeout: _timeout)
//      log("Smartlink Listener: TCP Socket connection initiated", .debug, #function, #file, #line)
//      
//    } catch _ {
//      throw WanListenerError.kFailedToConnect
//    }
//  }
  
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
    apiLog.debug("Smartlink Listener: STARTED pinging \(self._host ?? "????")")
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
    apiLog.debug("Smartlink Listener: TCP Socket didConnectToHost, \(host):\(port)")
    
    // initiate a secure (TLS) connection to the Smartlink server
    var tlsSettings = [String : NSObject]()
    tlsSettings[kCFStreamSSLPeerName as String] = kSmartlinkHost as NSObject
    _tcpSocket.startTLS(tlsSettings)
    
    apiLog.debug("Smartlink Listener: TLS Socket connection initiated")
  }
  
  public func socketDidSecure(_ sock: GCDAsyncSocket) {
    apiLog.debug("Smartlink Listener: TLS socketDidSecure")
    
    // start pinging SmartLink server
    startPinging()
    
    // register the Application / token pair with the SmartLink server
    sendTlsCommand("application register name=\(_appName!) platform=\(kPlatform) token=\(_currentTokens.idToken)", timeout: _timeout, tag: 0)
    apiLog.debug("Smartlink Listener: Application registered, name=\(self._appName!) platform=\(self.kPlatform)")

    // start reading
    _tcpSocket.readData(to: GCDAsyncSocket.lfData(), withTimeout: -1, tag: 0)
    apiLog.info("Smartlink Listener: STARTED")
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
    if err == nil {
      apiLog.debug("Smartlink Listener: TCP socketDidDisconnect \(error)")
    } else {
      apiLog.error("Smartlink Listener: TCP socketDidDisconnect \(error)")
    }
    if err != nil { stop() }
  }
  
  public func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
    return 0
  }
  
  public func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
    return 30.0
  }
}
