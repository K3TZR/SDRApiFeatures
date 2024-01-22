//
//  ObjectsCore.swift
//  SDRApiViewer
//
//  Created by Douglas Adams on 1/19/24.
//

import Cocoa
import ComposableArchitecture
import Foundation

import SettingsFeature
import SharedFeature

@Reducer
public struct ObjectsFeature {
  
  public init() {}
  
  @ObservableState
  public struct State {
    public var connectionState: ConnectionState
    
    public init(connectionState: ConnectionState = .disconnected) {
      self.connectionState = connectionState
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      return .none
    }
  }
}
