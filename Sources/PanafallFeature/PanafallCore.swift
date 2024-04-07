//
//  PanafallCore.swift
//
//
//  Created by Douglas Adams on 4/4/24.
//

import ComposableArchitecture
import Foundation

import FlexApiFeature
import SharedFeature

@Reducer
public struct PanafallCore {
  public init() {}
  
  @ObservableState
  public struct State {
    public init(panadapter: Panadapter, waterfall: Waterfall) {
      self.panadapter = panadapter
      self.waterfall = waterfall
    }

    var panadapter: Panadapter
    var waterfall: Waterfall

    @Shared(.appStorage("panafallLeftSideIsOpen")) var panafallLeftSideIsOpen = false
    @Shared(.appStorage("spectrumFillLevel")) var spectrumFillLevel: Double = 0
    @Shared(.appStorage("spectrumType")) var spectrumType: String = SpectrumType.line.rawValue
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    //    Reduce { state, action in
    //    }
  }
}
