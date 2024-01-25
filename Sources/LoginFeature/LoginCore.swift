//
//  LoginCore.swift
//  SDRApiViewer
//
//  Created by Douglas Adams on 12/30/23.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct LoginFeature {

  public init() {}

  @ObservableState
  public struct State {    
    var user: String
    var heading: String
    var message: String?
    var userLabel: String
    var pwdLabel: String
    var labelWidth: CGFloat
    var overallWidth: CGFloat

    public init(user: String, heading: String = "Please Login", message: String? = nil, userLabel: String = "User", pwdLabel: String = "Password", labelWidth: CGFloat = 100, overallWidth: CGFloat = 350 ) {
      self.user = user
      self.heading = heading
      self.message = message
      self.userLabel = userLabel
      self.pwdLabel = pwdLabel
      self.labelWidth = labelWidth
      self.overallWidth = overallWidth
    }
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)

    case cancelButtonTapped
    case loginButtonTapped(String, String)
  }
  
  public var body: some ReducerOf<Self> {

    BindingReducer()
    
    Reduce { state, action in
      return .none
//      switch action {
//
//      case let .loginButtonTapped(user, password):
//        print("LOGIN: loginButtonTapped, user = \(user), password = \(password)")
//        return .none
//      }
    }
  }
}
