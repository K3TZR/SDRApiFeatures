//
//  Ph1View.swift
//  ViewFeatures/Ph1Feature
//
//  Created by Douglas Adams on 11/15/22.
//

import SwiftUI

import LevelIndicatorView
import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

public struct Ph1View: View {

  public init() {}
  
  @Environment(ApiModel.self) private var apiModel
  
  public var body: some View {
    
    VStack {
      VStack(alignment: .leading, spacing: 10) {
        if let micMeter = apiModel.meterBy(shortName: .microphoneAverage) , let compressionMeter = apiModel.meterBy(shortName: .postClipper) {
          LevelIndicatorView(levels: SignalLevel(rms: micMeter.value, peak: 0), type: .micLevel)
          LevelIndicatorView(levels: SignalLevel(rms: compressionMeter.value, peak: 0), type: .compression)
        } else {
          LevelIndicatorView(levels: SignalLevel(rms: 0, peak: 0), type: .micLevel)
          LevelIndicatorView(levels: SignalLevel(rms: 1.0, peak: 0.0), type: .compression)
        }
        ProfileView(micProfile: apiModel.profiles[id: "mic"] ?? Profile("empty", apiModel))
        MicSelectionView(transmit: apiModel.transmit, radio: apiModel.radio ?? Radio(Packet(), apiModel))
        ProcView(transmit: apiModel.transmit)
        MonView(transmit: apiModel.transmit)
      }
      VStack(alignment: .center, spacing: 10) {
        AccView(transmit: apiModel.transmit)
        Divider().background(.blue)
      }
    }
  }
}

private struct ProfileView: View {
  var micProfile: Profile
  
  public var body: some View {
    HStack(spacing: 25) {
      Picker("", selection: Binding(
        get: { micProfile.current},
        set: { micProfile.setProperty("load", $0) })) {
          ForEach(micProfile.list, id: \.self) {
          Text($0).tag($0)
        }
      }
      .labelsHidden()
      .pickerStyle(.menu)
      .frame(width: 210, alignment: .leading)
      
      Button("Save", action: {})
        .font(.footnote)
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(.blue)
    }
  }
}

private struct MicSelectionView: View {
  var transmit: Transmit
  var radio: Radio

  public var body: some View {
    
    HStack(spacing: 10) {
      Picker("", selection: Binding(
        get: { transmit.micSelection },
        set: { transmit.setProperty(.micSelection, $0) })) {
          ForEach(radio.micList, id: \.self) {
            Text($0)
          }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(width: 70, alignment: .leading)
      
      HStack(spacing: 20) {
        Text("\(transmit.micLevel)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.micLevel) }, set: { transmit.setProperty(.micLevel, String(Int($0))) }), in: 0...100)
      }
    }
  }
}

private struct ProcView: View {
  var transmit: Transmit
  
  public var body: some View {
    VStack(spacing: 0) {
      
      HStack(spacing: 40) {
        Text("NOR")
        Text("DX")
        Text("DX+")
      }
      .padding(.leading, 125)
      .font(.footnote)
      
      HStack(spacing: 10) {
        Toggle(isOn: Binding(
          get: { transmit.speechProcessorEnabled },
          set: { transmit.setProperty(.speechProcessorEnabled, $0.as1or0) })) { Text("PROC").frame(width: 55)}
          .toggleStyle(.button)
        
        HStack(spacing: 20) {
          Text("\(transmit.speechProcessorLevel)").frame(width: 25, alignment: .trailing)
          Slider(value: Binding(get: { Double(transmit.speechProcessorLevel) }, set: { transmit.setProperty(.speechProcessorLevel, String(Int($0))) }), in: 0...100)
        }
      }
    }
  }
}

private struct MonView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    HStack(spacing: 10) {
      Toggle(isOn: Binding(
        get: { transmit.txMonitorEnabled },
        set: { transmit.setProperty(.txMonitorEnabled, $0.as1or0) })) { Text("MON").frame(width: 55)}
        .toggleStyle(.button)
      
      HStack(spacing: 20) {
        Text("\(transmit.ssbMonitorGain)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.ssbMonitorGain) }, set: { transmit.setProperty(.ssbMonitorGain, String(Int($0))) }), in: 0...100)
      }
    }
  }
}

private struct AccView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    HStack(alignment: .center, spacing: 40) {
      Toggle(isOn: Binding(
        get: { transmit.micAccEnabled },
        set: { transmit.setProperty(.micAccEnabled, $0.as1or0) })) { Text("ACC").frame(width: 40)}
        .toggleStyle(.button)
      
      Toggle(isOn: Binding(
        get: { transmit.daxEnabled },
        set: { transmit.setProperty(.daxEnabled, $0.as1or0) })) { Text("DAX").frame(width: 40)}
        .toggleStyle(.button)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview("Ph1") {
  Ph1View()
    .frame(width: 275, height: 250)
}
