//
//  DaxView.swift
//  ViewFeatures/DaxFeature
//
//  Created by Douglas Adams on 12/21/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

public struct DaxView: View {
  @Bindable var store: StoreOf<PanafallCore>

  public init(store: StoreOf<PanafallCore>) {
    self.store = store
  }
  
  public var body: some View {

    VStack(alignment: .leading) {
      HStack(spacing: 5) {
        Text("Dax IQ Channel")
        Picker("", selection: Binding(
          get: { store.panadapter.daxIqChannel },
          set: { store.panadapter.setProperty(.daxIqChannel, String($0)) })) {
            ForEach(store.panadapter.daxIqChoices, id: \.self) {
              Text(String($0)).tag($0)
            }
          }
          .labelsHidden()
          .pickerStyle(.menu)
          .frame(width: 50, alignment: .leading)
      }
    }
    .frame(width: 160)
    .padding(5)
  }
}

#Preview {
  DaxView(store: Store(initialState: PanafallCore.State(panadapter: Panadapter(1, ApiModel.shared), waterfall: Waterfall(1, ApiModel.shared))) {
    PanafallCore()
  })
    
    .frame(width: 160)
    .padding(5)
}
