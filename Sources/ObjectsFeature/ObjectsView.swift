//
//  ObjectsView.swift
//  SDRApiViewer
//
//  Created by Douglas Adams on 1/2/24.
//

import ComposableArchitecture
import SwiftUI

import SettingsFeature
import SharedFeature

public struct ObjectsView: View {
  @Bindable var store: StoreOf<ObjectsFeature>

  public init(store: StoreOf<ObjectsFeature>) {
    self.store = store
  }
  
  @Environment(SettingsModel.self) var settingsModel
  
  public var body: some View {
    @Bindable var settings = settingsModel
    
    VStack(alignment: .leading) {
      FilterObjectsView(store: store)
      
      if store.connectionState != .connected {
        VStack(alignment: .leading) {
          Spacer()
          HStack {
            Spacer()
            Text("API Objects will be displayed here")
            Spacer()
          }
          Spacer()
        }
        
      } else {
        ScrollView([.vertical]) {
          VStack(alignment: .leading) {
            RadioSubView()
            
            GuiClientSubView(store: store)

            if settingsModel.isGui == false {
              TesterSubView()
            }
          }
          .textSelection(.enabled)
          .font(.system(size: CGFloat(settingsModel.fontSize), weight: .regular, design: .monospaced))
          .padding(.horizontal, 10)
        }
      }
    }
  }
}
  
private struct FilterObjectsView: View {
  @Bindable var store: StoreOf<ObjectsFeature>
  
  @Environment(SettingsModel.self) var settingsModel
  
  var body: some View {
    @Bindable var settings = settingsModel

    HStack {
      Picker("Show Objects of type", selection: $settings.objectFilter) {
        ForEach(ObjectFilter.allCases, id: \.self) {
          Text($0.rawValue).tag($0.rawValue)
        }
      }
      .pickerStyle(MenuPickerStyle())
      .frame(width: 300)
    }
  }
}

#Preview {
  ObjectsView(store: Store(initialState: ObjectsFeature.State(connectionState: .disconnected)) {
    ObjectsFeature()
  })
}
