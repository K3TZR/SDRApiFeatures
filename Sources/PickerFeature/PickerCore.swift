//
//  PickerCore.swift
//  SDRApiViewer
//
//  Created by Douglas Adams on 12/28/23.
//

import ComposableArchitecture
import Foundation

import ListenerFeature
import SettingsFeature

@Reducer
public struct PickerFeature {
  
  public init() {}

  @ObservableState
  public struct State {

    public init() {}
  }
  
  public enum Action {
    case connectButtonTapped(String)
    case defaultButtonTapped(String)
    case testButtonTapped(String)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      
      switch action {

      case .connectButtonTapped(_):
        return .none
      
      case let .defaultButtonTapped(selection):
        return defaultButton(selection)

      case let .testButtonTapped(selection):
        return .run { _ in ListenerModel.shared.smartlinkTest(selection) }
      }
    }
  }

  // set/reset default values
  private func defaultButton(_ selection: String?) -> Effect<PickerFeature.Action> {
    if SettingsModel.shared.isGui {
      if SettingsModel.shared.guiDefault == selection {
        SettingsModel.shared.guiDefault = nil
      } else {
        SettingsModel.shared.guiDefault = selection
      }
      
    } else {
      if SettingsModel.shared.nonGuiDefault == selection {
        SettingsModel.shared.nonGuiDefault = nil
      } else {
        SettingsModel.shared.nonGuiDefault = selection
      }
    }
    return .none
  }
}
