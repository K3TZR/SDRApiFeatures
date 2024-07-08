//
//  EqView.swift
//  ViewFeatures/EqFeature
//
//  Created by Douglas Adams on 4/27/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

public struct EqView: View {
  @Bindable var store: StoreOf<SideControlsFeature>
  
  @Environment(ObjectModel.self) private var objectModel
  
  @MainActor private var equalizer: Equalizer? {
    objectModel.equalizers[id: store.rxEqualizerIsDisplayed ? "rxsc" : "txsc"]
  }
  
  public init(store: StoreOf<SideControlsFeature>) {
    self.store = store
  }
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 10) {
      if let equalizer {
        SliderView(eq: equalizer )
        FooterView(eq: equalizer, store: store )
      } else {
        DisabledSliderView()
        DisabledFooterView()
      }
      Divider().background(.blue)
    }
  }
}

private struct SliderView: View {
  var eq: Equalizer
  
  var body: some View {
    HStack {
      VStack(alignment: .trailing, spacing: 12) {
        Text("Hz")
        Text("63")
        Text("125")
        Text("250")
        Text("500")
        Text("1k")
        Text("2k")
        Text("4k")
        Text("8k")
      }
      VStack {
        HStack {
          Text("-10dB")
          Spacer()
          Text("+10dB")
        }
        Slider(value: Binding(get: { Double(eq.hz63)}, set: { eq.set(.hz63, String(Int($0))) }), in: -10...10, step: 1)
        Slider(value: Binding(get: { Double(eq.hz125)}, set: { eq.set(.hz125, String(Int($0))) }), in: -10...10, step: 1)
        Slider(value: Binding(get: { Double(eq.hz250)}, set: { eq.set(.hz250, String(Int($0))) }), in: -10...10, step: 1)
        Slider(value: Binding(get: { Double(eq.hz500)}, set: { eq.set(.hz500, String(Int($0))) }), in: -10...10, step: 1)
        Slider(value: Binding(get: { Double(eq.hz1000)}, set: { eq.set(.hz1000, String(Int($0))) }), in: -10...10, step: 1)
        Slider(value: Binding(get: { Double(eq.hz2000)}, set: { eq.set(.hz2000, String(Int($0))) }), in: -10...10, step: 1)
        Slider(value: Binding(get: { Double(eq.hz4000)}, set: { eq.set(.hz4000, String(Int($0))) }), in: -10...10, step: 1)
        Slider(value: Binding(get: { Double(eq.hz8000)}, set: { eq.set(.hz8000, String(Int($0))) }), in: -10...10, step: 1)
      }
      VStack(alignment: .trailing, spacing: 12) {
        Group {
          Text("")
          Text(eq.hz63, format: .number)
          Text(eq.hz125, format: .number)
          Text(eq.hz250, format: .number)
          Text(eq.hz500, format: .number)
          Text(eq.hz1000, format: .number)
          Text(eq.hz2000, format: .number)
          Text(eq.hz4000, format: .number)
          Text(eq.hz8000, format: .number)
        }.frame(width: 30)
      }
    }
  }
}

private struct FooterView: View {
  var eq: Equalizer
  @Bindable var store: StoreOf<SideControlsFeature>
  
  var body: some View {
    
    HStack(alignment: .center, spacing: 25) {
      Toggle("Enabled", isOn: Binding(get: {eq.eqEnabled}, set: {eq.set(.eqEnabled, $0.as1or0)}) )
      ControlGroup {
        Toggle("Rx", isOn: $store.rxEqualizerIsDisplayed)
        Toggle("Tx", isOn: $store.rxEqualizerIsDisplayed.not)
      }.toggleStyle(.button)
      Button("Flat", action: { eq.flat() } )
    }
  }
}

private struct DisabledSliderView: View {
  
  var body: some View {
    HStack {
      VStack(alignment: .trailing, spacing: 12) {
        Text("Hz")
        Text("63")
        Text("125")
        Text("250")
        Text("500")
        Text("1k")
        Text("2k")
        Text("4k")
        Text("8k")
      }
      VStack {
        HStack {
          Text("-10dB")
          Spacer()
          Text("+10dB")
        }
        Slider(value: .constant(0), in: -10...10, step: 1)
        Slider(value: .constant(0), in: -10...10, step: 1)
        Slider(value: .constant(0), in: -10...10, step: 1)
        Slider(value: .constant(0), in: -10...10, step: 1)
        Slider(value: .constant(0), in: -10...10, step: 1)
        Slider(value: .constant(0), in: -10...10, step: 1)
        Slider(value: .constant(0), in: -10...10, step: 1)
        Slider(value: .constant(0), in: -10...10, step: 1)
      }
      VStack(alignment: .trailing, spacing: 12) {
        Group {
          Text("")
          Text(0, format: .number)
          Text(0, format: .number)
          Text(0, format: .number)
          Text(0, format: .number)
          Text(0, format: .number)
          Text(0, format: .number)
          Text(0, format: .number)
          Text(0, format: .number)
        }.frame(width: 30)
      }
    }.disabled(true)
  }
}

private struct DisabledFooterView: View {
  
  var body: some View {
    
    HStack(alignment: .center, spacing: 25) {
      Toggle("Enabled", isOn: .constant(false))
      ControlGroup {
        Toggle("Rx", isOn: .constant(true))
        Toggle("Tx", isOn: .constant(false))
      }.toggleStyle(.button)
      Button("Flat", action: { } )
    }.disabled(true)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  EqView(store: Store(initialState: SideControlsFeature.State()) {
    SideControlsFeature()
  })
  
  .environment(ObjectModel())
  
  .frame(width: 275, height: 250)
  .padding()
}

// ----------------------------------------------------------------------------
// MARK: - Binding Extension

extension Binding where Value == Bool {
  // nagative bool binding same as `!Value`
  var not: Binding<Value> {
    Binding<Value> (
      get: { !self.wrappedValue },
      set: { self.wrappedValue = !$0}
    )
  }
}
