//
//  FlagAntennaView.swift
//  
//
//  Created by Douglas Adams on 6/12/23.
//

import SwiftUI

import FlexApiFeature

public struct FlagAntennaView: View {
  var slice: Slice
  
  public init(slice: Slice) {
    self.slice = slice
  }
  
  @Environment(ObjectModel.self) private var objectModel

  @MainActor var panadapter: Panadapter { objectModel.panadapters[id: slice.panadapterId]! }
  
  public var body: some View {
    
    VStack(alignment: .leading) {
      HStack {
        Text("Tx Antenna").frame(alignment: .leading)
        Picker("", selection: Binding(
          get: { slice.txAnt},
          set: { slice.set(.txAnt, $0) })) {
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
          set: { slice.set(.rxAnt, $0) })) {
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
          set: { panadapter.set(.loopAEnabled, $0.as1or0 ) } ))
        .toggleStyle(.button)
      }
      
      HStack {
        Text("Rf Gain")
        Text("\(panadapter.rfGain)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(panadapter.rfGain) }, set: { panadapter.set(.rfGain, String(Int($0))) }), in: -10...20, step: 10)
      }
    }
    .padding()
  }
}

#Preview {
  FlagAntennaView(slice: Slice(1, ObjectModel.shared))
    
    .environment(ObjectModel.shared)
  
    .frame(width: 200)
}
