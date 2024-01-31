//
//  PickerCore.swift
//  SDRApiFeature
//
//  Created by Douglas Adams on 12/28/23.
//

import ComposableArchitecture
import Foundation

import ListenerFeature

@Reducer
public struct PickerFeature {
  
  public init() {}

  @ObservableState
  public struct State {
    var isGui: Bool
    var defaultValue: String?
    
    public init(isGui: Bool, defaultValue: String?) {
      self.isGui = isGui
      self.defaultValue = defaultValue
    }
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
        return defaultButton(&state, selection)

      case let .testButtonTapped(selection):
        return .run { _ in ListenerModel.shared.smartlinkTest(selection) }
      }
    }
  }

  // set/reset default values
  private func defaultButton(_ state: inout State, _ selection: String?) -> Effect<PickerFeature.Action> {
    if state.defaultValue == selection {
      state.defaultValue = nil
    } else {
      state.defaultValue = selection
    }
    return .none
  }
}
