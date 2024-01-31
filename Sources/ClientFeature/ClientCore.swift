//
//  ClientCore.swift
//  SDRApiFeature
//
//  Created by Douglas Adams on 12/30/23.
//

import ComposableArchitecture
import Foundation

import SharedFeature

@Reducer
public struct ClientFeature {

  public init() {}

  @ObservableState
  public struct State {
    var heading: String
    var selection: String
    var guiClients: IdentifiedArrayOf<GuiClient>

    public init(heading: String = "Choose an Action", selection: String, guiClients: IdentifiedArrayOf<GuiClient>) {
      self.heading = heading
      self.selection = selection
      self.guiClients = guiClients
    }
  }
  
  public enum Action {
    case connect(String, UInt32?)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      return .none
//      switch action {
//
//      case let .connectButtonTapped(stringValue):
//        print("PICKER: connectButtonTapped, value = \(stringValue ?? "nil")")
//        return .none
//
//      case .defaultButtonTapped(_):
//        print("PICKER: defaultButtonTapped")
//        return .none
//
//      case let .testButtonTapped(stringValue):
//        print("PICKER: testButtonTapped, value = \(stringValue ?? "nil")")
//        return .none
//      }
    }
  }
}
