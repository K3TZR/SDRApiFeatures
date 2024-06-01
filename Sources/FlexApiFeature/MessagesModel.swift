//
//  MessagesModel.swift
//  SDRApiViewer
//
//  Created by Douglas Adams on 1/28/24.
//

import ComposableArchitecture
import Foundation

import SharedFeature

@Observable
public final class MessagesModel: TcpProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Singleton
  
  public static var shared = MessagesModel()
  private init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  @MainActor public var filteredMessages = IdentifiedArrayOf<TcpMessage>()
  public var showPings = false
  public var showAllReplies = false

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _filter: MessageFilter = .all
  private var _filterText = ""
  private var _messages = IdentifiedArrayOf<TcpMessage>()
  private var _startTime: Date?

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Clear messages
  public func clear(_ enabled: Bool = true) {
    if enabled {
      self._messages.removeAll()
      removeAllFilteredMessages()
    }
  }

  /// Set the messages filter parameters and re-filter
  public func reFilter(_ filter: MessageFilter, _ filterText: String) {
    _filter = filter
    _filterText = filterText
    reFilterMessages()
  }

  /// Process a TcpMessage
  /// - Parameter msg: a TcpMessage struct
  public func tcpProcessor(_ text: String, isInput: Bool) {

    if _startTime == nil { _startTime = Date() }
    let timeStamp = Date()

    // ignore routine replies (i.e. replies with no error or no attached data)
    func ignoreReply(_ text: String) -> Bool {
      if text.first == "R" && showAllReplies { return false } // showing all Replies (including ping replies)
      if text.first != "R" { return false }                   // not a Reply
      let parts = text.components(separatedBy: "|")
      if parts.count < 3 { return false }                     // incomplete
      if parts[1] != kNoError { return false }                // error of some type
      if parts[2] != "" { return false }                      // additional data present
      return true                                             // otherwise, ignore it
    }

    // ignore received replies unless they are non-zero or contain additional data
    if isInput && ignoreReply(text) { return }
    // ignore sent "ping" messages unless showPings is true
    if text.contains("ping") && showPings == false { return }

    let msg = TcpMessage(text: String(text), isInput: isInput, timeStamp: timeStamp, interval: timeStamp.timeIntervalSince(_startTime!))

    // filteredMessages is observed by a View therefore requires async updating on the MainActor
    Task {
      await MainActor.run {
        // add it to the backing collection
        _messages.append(msg)

        // add it to the public collection (if appropriate)
        switch (_filter, _filterText) {

        case (MessageFilter.all, _):        filteredMessages.append(msg)
        case (MessageFilter.prefix, ""):    filteredMessages.append(msg)
        case (MessageFilter.prefix, _):     if msg.text.localizedCaseInsensitiveContains("|" + _filterText) { filteredMessages.append(msg) }
        case (MessageFilter.includes, _):   if msg.text.localizedCaseInsensitiveContains(_filterText) { filteredMessages.append(msg) }
        case (MessageFilter.excludes, ""):  filteredMessages.append(msg)
        case (MessageFilter.excludes, _):   if !msg.text.localizedCaseInsensitiveContains(_filterText) { filteredMessages.append(msg) }
        case (MessageFilter.command, _):    if msg.text.prefix(1) == "C" { filteredMessages.append(msg) }
        case (MessageFilter.S0, _):         if msg.text.prefix(3) == "S0|" { filteredMessages.append(msg) }
        case (MessageFilter.status, _):     if msg.text.prefix(1) == "S" && msg.text.prefix(3) != "S0|" { filteredMessages.append(msg) }
        case (MessageFilter.reply, _):      if msg.text.prefix(1) == "R" { filteredMessages.append(msg) }
        }
      }
    }
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private filter methods
  
  /// Rebuild the entire filteredMessages array
  private func reFilterMessages() {
    var _filteredMessages = IdentifiedArrayOf<TcpMessage>()
    
    // re-filter the entire messages array
    switch (_filter, _filterText) {

    case (MessageFilter.all, _):        _filteredMessages = _messages
    case (MessageFilter.prefix, ""):    _filteredMessages = _messages
    case (MessageFilter.prefix, _):     _filteredMessages = _messages.filter { $0.text.localizedCaseInsensitiveContains("|" + _filterText) }
    case (MessageFilter.includes, _):   _filteredMessages = _messages.filter { $0.text.localizedCaseInsensitiveContains(_filterText) }
    case (MessageFilter.excludes, ""):  _filteredMessages = _messages
    case (MessageFilter.excludes, _):   _filteredMessages = _messages.filter { !$0.text.localizedCaseInsensitiveContains(_filterText) }
    case (MessageFilter.command, _):    _filteredMessages = _messages.filter { $0.text.prefix(1) == "C" }
    case (MessageFilter.S0, _):         _filteredMessages = _messages.filter { $0.text.prefix(3) == "S0|" }
    case (MessageFilter.status, _):     _filteredMessages = _messages.filter { $0.text.prefix(1) == "S" && $0.text.prefix(3) != "S0|"}
    case (MessageFilter.reply, _):      _filteredMessages = _messages.filter { $0.text.prefix(1) == "R" }
    }
    
    // filteredMessages is observed by a View therefore requires async updating on the MainActor
    Task { [_filteredMessages] in
      await MainActor.run { filteredMessages = _filteredMessages }
    }
  }
  
  private func removeAllFilteredMessages() {
    // filteredMessages is observed by a View therefore requires async updating on the MainActor
    Task {
      await MainActor.run { filteredMessages = IdentifiedArrayOf<TcpMessage>() }
    }
  }
}
