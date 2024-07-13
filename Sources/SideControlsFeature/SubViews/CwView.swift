//
//  CwView.swift
//  ViewFeatures/CwFeature
//
//  Created by Douglas Adams on 11/15/22.
//

import SwiftUI

import CustomControlFeature
import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

public struct CwView: View {
  
  public init() {}

  @Environment(ObjectModel.self) private var objectModel

  public var body: some View {
    VStack(alignment: .leading, spacing: 10)  {
      
      if let alcMeter = objectModel.meterBy(shortName: .hwAlc) {
        LevelIndicatorView(levels: SignalLevel(rms: alcMeter.value, peak: 0), type: .alc)
      } else {
        LevelIndicatorView(levels: SignalLevel(rms: 0.0, peak: 0.0), type: .alc)
      }
      
      HStack {
        ButtonsView(transmit: objectModel.transmit)
        SlidersView(transmit: objectModel.transmit)
      }
      
      BottomButtonsView(transmit: objectModel.transmit)
      Divider().background(.blue)
    }
  }
}

private struct ButtonsView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 13){
      Group {
        Text("Delay")
        Text("Speed")
        Toggle(isOn: Binding(
          get: { transmit.cwSidetoneEnabled },
          set: { transmit.set(.cwSidetoneEnabled, $0.as1or0) } )) {Text("Sidetone").frame(width: 55)}
          .toggleStyle(.button)
        Text("Pan")
      }
    }
  }
}

private struct SlidersView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    VStack(spacing: 8) {
      HStack(spacing: 10) {
        Text("\(transmit.cwBreakInDelay)").frame(width: 35, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.cwBreakInDelay) }, set: { transmit.set(.cwBreakInDelay, String(Int($0))) }), in: 30...2_000, step: 5)
      }
      HStack(spacing: 10) {
        Text("\(transmit.cwSpeed)").frame(width: 35, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.cwSpeed) }, set: { transmit.set(.cwSpeed, String(Int($0))) }), in: 0...100, step: 1)
      }
      HStack(spacing: 10) {
        Text("\(transmit.cwMonitorGain)").frame(width: 35, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.cwMonitorGain) }, set: { transmit.set(.cwMonitorGain, String(Int($0))) }), in: 0...100, step: 1)
      }
      HStack(spacing: 10) {
        Text("\(transmit.cwMonitorPan)").frame(width: 35, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.cwMonitorPan) }, set: { transmit.set(.cwMonitorPan, String(Int($0))) }), in: 0...100, step: 1)
      }
    }
  }
}

struct BottomButtonsView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    HStack(spacing: 10) {
      Group {
        Toggle(isOn: Binding(
          get: { transmit.cwBreakInEnabled },
          set: { transmit.set(.cwBreakInEnabled, $0.as1or0) } ))
        {Text("BrkIn").frame(width: 45)}
        
        Toggle(isOn: Binding(
          get: { transmit.cwIambicEnabled },
          set: { transmit.set(.cwIambicEnabled, $0.as1or0) } ))
        {Text("Iambic").frame(width: 45)}
      }
      .toggleStyle(.button)
      
      Text("Pitch").frame(width: 35)
      
      ApiIntView(value: transmit.cwPitch, action: { transmit.set(.cwPitch, $0)}, width: 50)
      
      Stepper("", value: Binding(
        get: { transmit.cwPitch },
        set: { transmit.set(.cwPitch, String($0)) } ),
              in: 100...6000,
              step: 50)
      .labelsHidden()
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  CwView()
    
    .environment(ObjectModel.shared)
    
    .frame(width: 275, height: 210)
}
