//
//  Logging.swift
//  SharedFeatures/Shared
//
//  Created by Douglas Adams on 11/29/22.
//

import Foundation

// ----------------------------------------------------------------------------
// MARK: - Public properties

//public typealias Log = (_ msg: String, _ level: LogLevel, _ function: StaticString, _ file: StaticString, _ line: Int) -> Void
//public typealias LogProperty = (_ msg: String, _ level: LogLevel) -> Void

public var logEntries: AsyncStream<LogEntry> {
  AsyncStream { continuation in _logStream = { logEntry in continuation.yield(logEntry) }
    continuation.onTermination = { @Sendable _ in } }}

public var logAlerts: AsyncStream<LogEntry> {
  AsyncStream { continuation in _logAlertStream = { logEntry in continuation.yield(logEntry) }
    continuation.onTermination = { @Sendable _ in } }}

public struct LogEntry: Equatable {
  public static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
    guard lhs.msg == rhs.msg else { return false }
    guard lhs.level == rhs.level else { return false }
    guard lhs.level == rhs.level else { return false }
    guard lhs.function.description == rhs.function.description else { return false }
    guard lhs.file.description == rhs.file.description else { return false }
    guard lhs.line == rhs.line else { return false }
    return true
  }
  
  public var msg: String
  public var level: LogLevel
  public var function: StaticString
  public var file: StaticString
  public var line: Int
  
  public init(_ msg: String, _ level: LogLevel, _ function: StaticString, _ file: StaticString, _ line: Int ) {
    self.msg = msg
    self.level = level
    self.function = function
    self.file = file
    self.line = line
  }
}

public enum LogLevel: String, CaseIterable {
    case debug
    case info
    case warning
    case error
}

// ----------------------------------------------------------------------------
// MARK: - Private properties

private var _logStream: (LogEntry) -> Void = { _ in }
private var _logAlertStream: (LogEntry) -> Void = { _ in }

// ----------------------------------------------------------------------------
// MARK: - Public methods

/// Given the domain and App name, ensure that the Log folder exista
/// - Parameters:
///   - info: a tuple of domain and app name
///   - folderUrl: the URL of the log folder
/// - Returns: the URL of the log file (or nil)
public func setupLogFolder(_ info: (domain: String, appName: String), _ folderUrl: URL) -> URL? {
  // try to create it
  do {
    try FileManager().createDirectory( at: folderUrl, withIntermediateDirectories: true, attributes: nil)
  } catch {
    return nil
  }
  return folderUrl.appending(path: info.appName + ".log")
}

/// Place log messages into the Log stream
/// - Parameters:
///   - msg: a text message
///   - level: the message level
///   - function: the function originating the entry
///   - file: the file originating the entry
///   - line: the line originating the entry
public func log(_ msg: String, _ level: LogLevel, _ function: StaticString, _ file: StaticString, _ line: Int) {
  _logStream( LogEntry(msg, level, function, file, line) )
  if level == .warning || level == .error {
    _logAlertStream(LogEntry(msg, level, function, file, line) )
  }
}



//@Observable
//final public class Logger {
//  // ----------------------------------------------------------------------------
//  // MARK: - Public properties
//
//  public var entry: LogEntry?
//  public var alertEntry: LogEntry?
//  public var folderUrl: URL?
//  public var fileUrl: URL?
//
//  // ----------------------------------------------------------------------------
//  // MARK: - Initialization
//
//  public init(_ group: String? = nil) {
//    let info = getInfo()
//    
//    if group == nil {
//      // the app is using a normal Container
//      let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//      folderUrl = url.appending(path: "Logs")
//
//    } else {
//      // the app is using a Group Container
//      let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: group!)
//      folderUrl  = url?.appending(path: "Library/Application Support/Logs")
//    }
//
//    if let folderUrl {
//      // try to create log folder
//      do {
//        try FileManager().createDirectory( at: folderUrl, withIntermediateDirectories: true, attributes: nil)
//      } catch {
//        fatalError("Unable to obtain Log file URL")
//      }
//      // make the file URL
//      fileUrl = folderUrl.appending(path: info.appName + ".log")
//      
//    } else {
//      fatalError("Unable to obtain Log file URL")
//    }
//  }
//
//  // ----------------------------------------------------------------------------
//  // MARK: - Public methods
//
//  /// Make a log messages available to the Logger
//  /// - Parameters:
//  ///   - msg: a text message
//  ///   - level: the message level
//  public func log(_ msg: String, _ level: LogLevel) {
//    entry = LogEntry(msg: msg, level: level)
//    if level == .warning || level == .error {
//      alertEntry = LogEntry(msg: msg, level: level)
//    }
//  }
//
//  // ----------------------------------------------------------------------------
//  // MARK: - Private methods
//
//  private func getInfo() -> (domain: String, appName: String) {
//    let bundleIdentifier = Bundle.main.bundleIdentifier!
//    let separator = bundleIdentifier.lastIndex(of: ".")!
//    let appName = String(bundleIdentifier.suffix(from: bundleIdentifier.index(separator, offsetBy: 1)))
//    let domain = String(bundleIdentifier.prefix(upTo: separator))
//    return (domain, appName)
//  }
//
//}
