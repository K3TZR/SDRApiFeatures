//
//  FlagAntennaView.swift
//  
//
//  Created by Douglas Adams on 6/12/23.
//

import SwiftUI

import FlexApi

public struct FlagAntennaView: View {
  var slice: Slice
  
  public init(slice: Slice) {
    self.slice = slice
  }
  
  @Environment(ApiModel.self) private var apiModel

  @MainActor var panadapter: Panadapter { apiModel.panadapters[id: slice.panadapterId]! }
  
  public var body: some View {
    
    VStack(alignment: .leading) {
      HStack {
        Text("Tx Antenna").frame(alignment: .leading)
        Picker("", selection: Binding(
          get: { slice.txAnt},
          set: { slice.setProperty(.txAnt, $0) })) {
            ForEach(slice.txAntList, id: \.self) {
              Text($0).tag($0)
            }
          }
          .labelsHidden()
      }
      Divider().background(Color(.blue))
      HStack {
        Text("Rx Antenna").frame(alignment: .leading)
        Picker("", selection: Binding(
          get: { slice.rxAnt},
          set: { slice.setProperty(.rxAnt, $0) })) {
            ForEach(slice.rxAntList, id: \.self) {
              Text($0).tag($0)
            }
          }
          .labelsHidden()
      }
      HStack {
        Spacer()
        Toggle("Loop A", isOn: Binding(
          get: { panadapter.loopAEnabled },
          set: { panadapter.setProperty(.loopAEnabled, $0.as1or0 ) } ))
        .toggleStyle(.button)
      }
      
      HStack {
        Text("Rf Gain")
        Text("\(panadapter.rfGain)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(panadapter.rfGain) }, set: { panadapter.setProperty(.rfGain, String(Int($0))) }), in: -10...20, step: 10)
      }
    }
    .padding()
  }
}

#Preview {
  FlagAntennaView(slice: Slice(1))
    .frame(width: 200)
}
