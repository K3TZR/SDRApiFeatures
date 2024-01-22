//
//  MessagesCore.swift
//
//
//  Created by Douglas Adams on 1/17/24.
//

import Cocoa
import ComposableArchitecture
import Foundation

import SettingsFeature
import SharedFeature

@Reducer
public struct MessagesFeature {
  
  public init() {}
  
  @ObservableState
  public struct State {
    
    public init() {}
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)

    case saveButtonTapped
    case clearFilterTextTapped
    case clearButtonTapped
  }
  
  public var body: some ReducerOf<Self> {
    
    Reduce { state, action in
      switch action {
      
      case .clearButtonTapped:
        MessagesModel.shared.clearAll()
        return .none
        
      case .clearFilterTextTapped:
        SettingsModel.shared.messageFilterText = ""
        MessagesModel.shared.reFilter()
        return .none

      case .saveButtonTapped:
        return saveMessages(MessagesModel.shared)
        
      case .binding(_):
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

