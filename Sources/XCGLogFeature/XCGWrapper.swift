//
//  XCGWrapper.swift
//  UtilityFeatures/XCGWrapper
//
//  Created by Douglas Adams on 12/20/21.
//

import Foundation
import Combine
import XCGLogger
import ObjcExceptionBridging

import SharedFeature

final public class XCGWrapper {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let log: XCGLogger
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
    
  private var _cancellable: AnyCancellable?
  private var _folderUrl: URL!
  private var _log: XCGLogger!

  private let kMaxLogFiles: UInt8  = 10
  private let kMaxTime: TimeInterval = 60 * 60 // 1 Hour
  
  // ----------------------------------------------------------------------------
  // MARK: - INitialization
  
  public init(logLevel: LogLevel = .debug, group: String? = nil) {

    var xcgLogLevel: XCGLogger.Level
    switch logLevel {
    case .debug:
      xcgLogLevel = XCGLogger.Level.debug
    case .info:
      xcgLogLevel = XCGLogger.Level.info
    case .warning:
      xcgLogLevel = XCGLogger.Level.warning
    case .error:
      xcgLogLevel = XCGLogger.Level.error
    }
    
    let info: (domain: String, appName: String) = {
      let bundleIdentifier = Bundle.main.bundleIdentifier!
      let separator = bundleIdentifier.lastIndex(of: ".")!
      let appName = String(bundleIdentifier.suffix(from: bundleIdentifier.index(separator, offsetBy: 1)))
      let domain = String(bundleIdentifier.prefix(upTo: separator))
      return (domain, appName)
    }()
    
    log = XCGLogger(identifier: info.appName, includeDefaultDestinations: false)
    
    if group == nil {
      // the app is using a normal Container
      let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
      _folderUrl = url.appending(path: "Logs")

    } else {
      // the app is using a Group Container
      let url = FileManager().containerURL(forSecurityApplicationGroupIdentifier: group!)
      _folderUrl  = url?.appending(path: "Library/Application Support/Logs")
    }

#if DEBUG
    // for DEBUG only
    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: info.appName + ".systemDestination")
    
    // Optionally set some configuration options
    systemDestination.outputLevel           = xcgLogLevel
    systemDestination.showFileName          = false
    systemDestination.showFunctionName      = false
    systemDestination.showLevel             = true
    systemDestination.showLineNumber        = false
    systemDestination.showLogIdentifier     = false
    systemDestination.showThreadName        = false
    
    // Add the destination to the logger
    log.add(destination: systemDestination)
#endif
    
    // Get / Create a file log destination
    if let logs = setupLogFolder(info, _folderUrl) {
      let fileDestination = AutoRotatingFileDestination(writeToFile: logs,
                                                        identifier: info.appName + ".autoRotatingFileDestination",
                                                        shouldAppend: true,
                                                        appendMarker: "- - - - - App was restarted - - - - -")
      
      // Optionally set some configuration options
      fileDestination.outputLevel             = xcgLogLevel
      fileDestination.showDate                = true
      fileDestination.showFileName            = false
      fileDestination.showFunctionName        = false
      fileDestination.showLevel               = true
      fileDestination.showLineNumber          = false
      fileDestination.showLogIdentifier       = false
      fileDestination.showThreadName          = false
      fileDestination.targetMaxLogFiles       = kMaxLogFiles
      fileDestination.targetMaxTimeInterval   = kMaxTime
      
      // Process this destination in the background
      fileDestination.logQueue = XCGLogger.logQueue
      
      // Add the destination to the logger
      log.add(destination: fileDestination)
      
      // Add basic app info, version info etc, to the start of the logs
      log.logAppDetails()
      
      // format the date (only effects the file logging)
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
      dateFormatter.locale = Locale.current
      log.dateFormatter = dateFormatter
      
      // subscribe to Log requests
      Task {
        for await entry in logEntries {
          // Log Handler to support XCGLogger
          switch entry.level {
            
          case .debug:    log.debug(entry.msg)
          case .info:     log.info(entry.msg)
          case .warning:  log.warning(entry.msg)
          case .error:    log.error(entry.msg)
          }
        }
      }

    } else {
      fatalError("Logging failure:, unable to find / create Log folder")
    }
  }
}
