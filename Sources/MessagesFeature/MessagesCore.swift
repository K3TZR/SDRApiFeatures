//
//  MessagesCore.swift
//
//
//  Created by Douglas Adams on 1/17/24.
//

import Cocoa
import ComposableArchitecture
import Foundation

import SharedFeature

@Reducer
public struct MessagesFeature {
  
  public init() {}
  
  @ObservableState
  public struct State {
    public var filterText: String
    public var filter: MessageFilter
    var fontSize: Int
    public var showTimes: Bool
    public var showPings: Bool
    public var clearOnStart: Bool
    public var clearOnStop: Bool

    var gotoTop: Bool
    
    public init(filterText: String, filter: MessageFilter, fontSize: Int, showTimes: Bool, showPings: Bool, clearOnStart: Bool, clearOnStop: Bool) {
      self.filterText = filterText
      self.filter = filter
      self.fontSize = fontSize
      self.showTimes = showTimes
      self.showPings = showPings
      self.clearOnStart = clearOnStart
      self.clearOnStop = clearOnStop
      
      self.gotoTop = false
    }
  }
  
  public enum Action {
    case saveButtonTapped
    case clearFilterTextTapped
    case clearButtonTapped
    case clearOnStartChanged(Bool)
    case clearOnStopChanged(Bool)
    case filterChanged(MessageFilter)
    case filterTextChanged(String)
    case gotoTopChanged(Bool)
    case showPingsChanged(Bool)
    case showTimesChanged(Bool)
  }
  
  public var body: some ReducerOf<Self> {
    
    Reduce { state, action in
      switch action {
      case .clearButtonTapped:
        MessagesModel.shared.clearAll()
        return .none
        
      case .clearFilterTextTapped:
        MessagesModel.shared.reFilter(filterText: state.filterText)
        return .none

      case let .clearOnStartChanged(newValue):
        state.clearOnStart = newValue
        return .none

      case let .clearOnStopChanged(newValue):
        state.clearOnStop = newValue
        return .none

      case let .filterChanged(newValue):
        state.filter = newValue
        MessagesModel.shared.reFilter(filter: state.filter)
        return .none

      case let .filterTextChanged(newValue):
        state.filterText = newValue
        MessagesModel.shared.reFilter(filterText: state.filterText)
        return .none

      case let .gotoTopChanged(newValue):
        state.gotoTop = newValue
        return .none

      case .saveButtonTapped:
        return saveMessages(MessagesModel.shared)
        
      case let .showPingsChanged(newValue):
        state.showPings = newValue
        MessagesModel.shared.showPings = newValue
        return .none

      case let .showTimesChanged(newValue):
        state.showTimes = newValue
        return .none
      }
    }
  }

  private func saveMessages(_ messagesModel: MessagesModel) -> Effect<MessagesFeature.Action> {
    let savePanel = NSSavePanel()
    savePanel.nameFieldStringValue = "SDRApi.messages"
    savePanel.canCreateDirectories = true
    savePanel.isExtensionHidden = false
    savePanel.allowsOtherFileTypes = false
    savePanel.title = "Save TCP Messages"
    
    let response = savePanel.runModal()
    if response == .OK {
      return .run { _ in
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 6
        formatter.positiveFormat = " * ##0.000000"
        
        let textArray = messagesModel.filteredMessages.map { formatter.string(from: NSNumber(value: $0.interval))! + " " + $0.text }
        let fileTextArray = textArray.joined(separator: "\n")
        try? await fileTextArray.write(to: savePanel.url!, atomically: true, encoding: .utf8)
      }
    } else {
      return .none
    }
  }
}

