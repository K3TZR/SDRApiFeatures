//
//  DisplayView.swift
//  ViewFeatures/DisplayFeature
//
//  Created by Douglas Adams on 12/21/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import SharedFeature

public struct DisplayView: View {
  @Bindable var store: StoreOf<PanafallCore>
  
  @Environment(ApiModel.self) private var apiModel

  public init(store: StoreOf<PanafallCore>) {
    self.store = store
  }
  
  public var body: some View {
      
      VStack(alignment: .leading) {
        PanadapterSettings(store: store )
        Divider().foregroundColor(.blue)
        if store.panadapter.waterfallId == 0 {
          EmptyView()
        } else {
          WaterfallSettings(store: store)
        }
      }
      .frame(width: 250)
      .padding(5)
  }
}

private struct PanadapterSettings: View {
  @Bindable var store: StoreOf<PanafallCore>
  
  var body: some View {
    
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        Text("Average").frame(width: 90, alignment: .leading)
        Text("\(store.panadapter.average)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(store.panadapter.average) }, set: { store.panadapter.setProperty(.average, String(Int($0))) }), in: 0...100)
      }
      HStack(spacing: 10) {
        Text("Frames/sec").frame(width: 90, alignment: .leading)
        Text("\(store.panadapter.fps)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(store.panadapter.fps) }, set: { store.panadapter.setProperty(.fps, String(Int($0))) }), in: 0...100)
      }
      HStack(spacing: 10) {
        Picker("", selection: $store.spectrumType) {
          ForEach(SpectrumType.allCases, id: \.self) { type in
            Text(type.rawValue).tag(type.rawValue)
          }
        }
        .labelsHidden()
        .frame(width: 90)
        
        Text("\(Int(store.spectrumFillLevel))").frame(width: 25, alignment: .trailing)
        Slider(value: $store.spectrumFillLevel, in: 0...100)
//        Slider(value: viewStore.binding(get: {_ in Double(panadapter.fillLevel) }, send: { .panadapterProperty(panadapter, .fillLevel, String(Int($0))) }), in: 0...100)
      }
      HStack {
        Text("Weighted Average").frame(width: 130, alignment: .leading)
        Toggle("", isOn: Binding(
          get: { store.panadapter.weightedAverageEnabled },
          set: { store.panadapter.setProperty(.weightedAverageEnabled, $0.as1or0 ) } ))
      }
    }
  }
}

private struct WaterfallSettings: View {
  @Bindable var store: StoreOf<PanafallCore>

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack (spacing: 45){
        Text("Color Gradient")
        Picker("", selection: Binding(
          get: { store.waterfall.gradientIndex},
          set: { store.waterfall.setProperty(.gradientIndex, String($0)) })) {
            ForEach(Array(Waterfall.gradients.enumerated()), id: \.offset) { index, element in
              Text(element).tag(index)
            }
          }
          .labelsHidden()
          .pickerStyle(.menu)
          .frame(width: 70, alignment: .leading)
      }
      
      HStack(spacing: 10) {
        Text("Color Gain").frame(width: 90, alignment: .leading)
        Text("\(store.waterfall.colorGain)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(store.waterfall.colorGain) }, set: { store.waterfall.setProperty(.colorGain, String(Int($0))) }), in: 0...100)
      }
      HStack(spacing: 10) {
        Text("Auto Black").frame(width: 65, alignment: .leading)
        Toggle("", isOn: Binding(
          get: { store.waterfall.autoBlackEnabled },
          set: { store.waterfall.setProperty(.autoBlackEnabled, $0.as1or0) } )).labelsHidden()
        Text("\(store.waterfall.blackLevel)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(store.waterfall.blackLevel) }, set: { store.waterfall.setProperty(.blackLevel, String(Int($0))) }), in: 0...100)
      }
      HStack(spacing: 10) {
        Text("Line Duration").frame(width: 90, alignment: .leading)
        Text("\(store.waterfall.lineDuration)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(store.waterfall.lineDuration) }, set: { store.waterfall.setProperty(.lineDuration, String(Int($0))) }), in: 0...100)
      }
    }
  }
}

#Preview {
  DisplayView(store: Store(initialState: PanafallCore.State(panadapter: Panadapter(1, ApiModel.shared), waterfall: Waterfall(1, ApiModel.shared))) {
    PanafallCore()
  })
    
  .frame(width: 250)
    .padding(5)
}
