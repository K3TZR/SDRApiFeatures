//
//  ControlsFeature.swift
//
//
//  Created by Douglas Adams on 4/1/24.
//

import ComposableArchitecture
import Foundation

import FlexApiFeature
import SharedFeature

@Reducer
public struct SideControlsFeature {
  public init() {}
  
  @ObservableState
  public struct State {
    public init() {}
    
    @Shared(.appStorage("controlsSelections")) var controlsSelections: ControlsOptions = .all

    
    // Equalizer
    @Shared(.appStorage("rxEqualizerIsDisplayed")) var rxEqualizerIsDisplayed = true

  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    
    case flatButtonTapped
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
        Reduce { state, action in
          switch action {
          
          case .binding(_):
            return .none
          
          case .flatButtonTapped:
            return .none
          }
        }
  }
}
