//
//  DirectCore.swift
//  
//
//  Created by Douglas Adams on 1/8/24.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct DirectFeature {

  public init() {}

  @ObservableState
  public struct State {
    var ip: String
    var heading: String
    var message: String?
    var labelWidth: CGFloat
    var overallWidth: CGFloat

    public init(ip: String, heading: String = "Enter the Address of a Radio", message: String? = nil, labelWidth: CGFloat = 100, overallWidth: CGFloat = 350 ) {
      self.ip = ip
      self.heading = heading
      self.message = message
      self.labelWidth = labelWidth
      self.overallWidth = overallWidth
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)

    case cancelButtonTapped
    case saveButtonTapped(String)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      return .none
    }
  }
}
