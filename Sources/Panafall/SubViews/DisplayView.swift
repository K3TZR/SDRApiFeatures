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

@Reducer
public struct DisplayCore {
  public init() {}
  
  @ObservableState
  public struct State {
    public init() {}

    @Shared(.appStorage("spectrumFillLevel")) var spectrumFillLevel: Double = 0
    @Shared(.appStorage("spectrumType")) var spectrumType: String = SpectrumType.line.rawValue
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()
    
    //    Reduce { state, action in
    //    }
  }
}

public struct DisplayView: View {
  @Bindable var store: StoreOf<DisplayCore>
  var panadapter: Panadapter
  
  @Environment(ApiModel.self) private var apiModel

  public init(store: StoreOf<DisplayCore>, panadapter: Panadapter) {
    self.store = store
    self.panadapter = panadapter
  }
  
  public var body: some View {
      
      VStack(alignment: .leading) {
        PanadapterSettings(store: store, panadapter: panadapter )
        Divider().foregroundColor(.blue)
        if panadapter.waterfallId == 0 {
          EmptyView()
        } else {
          WaterfallSettings(waterfall: apiModel.waterfalls[id: panadapter.waterfallId]!)
        }
      }
      .frame(width: 250)
      .padding(5)
  }
}

private struct PanadapterSettings: View {
  @Bindable var store: StoreOf<DisplayCore>
  var panadapter: Panadapter
  

  var body: some View {
    
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 10) {
        Text("Average").frame(width: 90, alignment: .leading)
        Text("\(panadapter.average)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(panadapter.average) }, set: { panadapter.setProperty(.average, String(Int($0))) }), in: 0...100)
      }
      HStack(spacing: 10) {
        Text("Frames/sec").frame(width: 90, alignment: .leading)
        Text("\(panadapter.fps)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(panadapter.fps) }, set: { panadapter.setProperty(.fps, String(Int($0))) }), in: 0...100)
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
          get: { panadapter.weightedAverageEnabled },
          set: { panadapter.setProperty(.weightedAverageEnabled, $0.as1or0 ) } ))
      }
    }
  }
}

private struct WaterfallSettings: View {
  var waterfall: Waterfall

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack (spacing: 45){
        Text("Color Gradient")
        Picker("", selection: Binding(
          get: { waterfall.gradientIndex},
          set: { waterfall.setProperty(.gradientIndex, String($0)) })) {
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
        Text("\(waterfall.colorGain)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(waterfall.colorGain) }, set: { waterfall.setProperty(.colorGain, String(Int($0))) }), in: 0...100)
      }
      HStack(spacing: 10) {
        Text("Auto Black").frame(width: 65, alignment: .leading)
        Toggle("", isOn: Binding(
          get: { waterfall.autoBlackEnabled },
          set: { waterfall.setProperty(.autoBlackEnabled, $0.as1or0) } )).labelsHidden()
        Text("\(waterfall.blackLevel)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(waterfall.blackLevel) }, set: { waterfall.setProperty(.blackLevel, String(Int($0))) }), in: 0...100)
      }
      HStack(spacing: 10) {
        Text("Line Duration").frame(width: 90, alignment: .leading)
        Text("\(waterfall.lineDuration)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(waterfall.lineDuration) }, set: { waterfall.setProperty(.lineDuration, String(Int($0))) }), in: 0...100)
      }
    }
  }
}

#Preview {
  DisplayView(store: Store(initialState: DisplayCore.State()) {
    DisplayCore()
  }, panadapter: Panadapter(0x49999990, ApiModel.shared))
    
  .frame(width: 250)
    .padding(5)
}
