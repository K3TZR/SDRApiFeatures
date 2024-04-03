//
//  AntennaView.swift
//  ViewFeatures/AntennaFeature
//
//  Created by Douglas Adams on 12/21/22.
//

import SwiftUI

import FlexApi

public struct AntennaView: View {
  var panadapter: Panadapter
  
  public init(panadapter: Panadapter) {
    self.panadapter = panadapter
  }
  
  public var body: some View {
    
    VStack(alignment: .leading) {
      HStack(spacing: 45) {
        Text("RxAnt")
        Picker("RxAnt", selection: Binding(
          get: { panadapter.rxAnt },
          set: { panadapter.setProperty(.rxAnt, $0) })) {
            ForEach(panadapter.antList, id: \.self) {
              Text($0).tag($0)
            }
          }
          .labelsHidden()
        //            .pickerStyle(.automatic)
          .frame(width: 70, alignment: .leading)
      }
      Toggle("Loop A", isOn: Binding(
        get: { panadapter.loopAEnabled },
        set: { panadapter.setProperty(.loopAEnabled, $0.as1or0 ) } ))
      .toggleStyle(.button)
      
      HStack {
        Text("Rf Gain")
        Text("\(panadapter.rfGain)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(panadapter.rfGain) }, set: { panadapter.setProperty(.rfGain, String(Int($0))) }), in: -10...20, step: 10)
      }
    }
    .frame(width: 160)
    .padding(5)
  }
}

#Preview {
  AntennaView(panadapter: Panadapter(0x49999999))
    .frame(width: 160)
    .padding(5)
}
