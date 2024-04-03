//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 6/25/23.
//

import SwiftUI

import FlexApi

struct DspView: View {
  var slice: Slice
  
  var body: some View {
    Grid (verticalSpacing: 5){
      GridRow {
        Toggle(isOn: Binding(
          get: { slice.wnbEnabled },
          set: { slice.setProperty(.wnbEnabled, $0.as1or0) })) { Text("WNB").frame(width: 40) }
          .toggleStyle(.button)
        Slider(value: Binding(
          get: { Double(slice.wnbLevel)},
          set: { slice.setProperty(.wnbLevel, String(Int($0))) } ), in: 0...100)
        Text(String(format: "%d",slice.wnbLevel))
          .frame(width: 30)
          .font(.title3)
          .multilineTextAlignment(.trailing)
      }
      GridRow {
        Toggle(isOn: Binding(
          get: { slice.nbEnabled},
          set: { slice.setProperty(.nbEnabled, $0.as1or0) })) { Text("NB").frame(width: 40) }
          .toggleStyle(.button)
        Slider(value: Binding(
          get: { Double(slice.nbLevel)},
          set: { slice.setProperty(.nbLevel, String(Int($0))) } ), in: 0...100)
        Text(String(format: "%d",slice.nbLevel))
          .frame(width: 30)
          .font(.title3)
          .multilineTextAlignment(.trailing)
      }.controlSize(.mini)
      
      GridRow {
        Toggle(isOn: Binding(
          get: { slice.nrEnabled},
          set: { slice.setProperty(.nrEnabled, $0.as1or0) })) { Text("NR").frame(width: 40) }
          .toggleStyle(.button)
        Slider(value: Binding(
          get: { Double(slice.nrLevel)},
          set: { slice.setProperty(.nrLevel, String(Int($0))) } ), in: 0...100)
        Text(String(format: "%d",slice.nrLevel))
          .frame(width: 30)
          .font(.title3)
          .multilineTextAlignment(.trailing)
      }.controlSize(.mini)
      
      GridRow {
        Toggle(isOn: Binding(
          get: { slice.anfEnabled},
          set: { slice.setProperty(.anfEnabled, $0.as1or0) })) { Text("ANF").frame(width: 40) }
          .toggleStyle(.button)
        Slider(value: Binding(
          get: { Double(slice.anfLevel)},
          set: { slice.setProperty(.anfLevel, String(Int($0))) } ), in: 0...100)
        Text(String(format: "%d", slice.anfLevel))
          .frame(width: 30)
          .font(.title3)
          .multilineTextAlignment(.trailing)
      }
    }
    .controlSize(.small)
  }
}
