//
//  PickerCore.swift
//  SDRApiViewer
//
//  Created by Douglas Adams on 12/28/23.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct PickerFeature {

  @ObservableState
  public struct State {
    var isGui: Bool
    var guiDefault: String?
    var nonGuiDefault: String?
    var testResult = false

    public init(isGui: Bool, guiDefault: String?, nonGuiDefault: String?, testResult: Bool = false) {
      self.isGui = isGui
      self.guiDefault = guiDefault
      self.nonGuiDefault = nonGuiDefault
      self.testResult = testResult
    }
  }
  
  public enum Action {
    case connectButtonTapped(String)
    case defaultButtonTapped(String)
    case testButtonTapped(String)
    
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