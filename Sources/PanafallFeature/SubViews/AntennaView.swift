//
//  AntennaView.swift
//  ViewFeatures/AntennaFeature
//
//  Created by Douglas Adams on 12/21/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

public struct AntennaView: View {
  @Bindable var store: StoreOf<PanafallCore>

  public init(store: StoreOf<PanafallCore>) {
    self.store = store
  }
  
  public var body: some View {
    
    VStack(alignment: .leading) {
      HStack(spacing: 45) {
        Text("RxAnt")
        Picker("RxAnt", selection: Binding(
          get: { store.panadapter.rxAnt },
          set: { store.panadapter.setProperty(.rxAnt, $0) })) {
            ForEach(store.panadapter.antList, id: \.self) {
              Text($0).tag($0)
            }
          }
          .labelsHidden()
        //            .pickerStyle(.automatic)
          .frame(width: 70, alignment: .leading)
      }
      Toggle("Loop A", isOn: Binding(
        get: { store.panadapter.loopAEnabled },
        set: { store.panadapter.setProperty(.loopAEnabled, $0.as1or0 ) } ))
      .toggleStyle(.button)
      
      HStack {
        Text("Rf Gain")
        Text("\(store.panadapter.rfGain)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(store.panadapter.rfGain) }, set: { store.panadapter.setProperty(.rfGain, String(Int($0))) }), in: -10...20, step: 10)
      }
    }
    .frame(width: 160)
    .padding(5)
  }
}

#Preview {
  AntennaView(store: Store(initialState: PanafallCore.State(panadapter: Panadapter(1), waterfall: Waterfall(1))) {
    PanafallCore()
  })
    
    .frame(width: 160)
    .padding(5)
}
