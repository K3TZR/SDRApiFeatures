//
//  TxView.swift
//  ViewFeatures/TxFeature
//
//  Created by Douglas Adams on 11/15/22.
//

import SwiftUI

import LevelIndicatorView
import FlexApiFeature
import SharedFeature

public struct TxView: View {
  
  public init() {}

  @Environment(ApiModel.self) private var apiModel

  public var body: some View {
    VStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 10)  {
        if let powerMeter = apiModel.meterBy(shortName: .powerForward), let swrMeter = apiModel.meterBy(shortName: .swr) {
          LevelIndicatorView(levels: SignalLevel(rms: powerMeter.value.powerFromDbm, peak: 0), type: .power)
          LevelIndicatorView(levels: SignalLevel(rms: swrMeter.value, peak: 0), type: .swr)
        } else {
          LevelIndicatorView(levels: SignalLevel(rms: 0.0, peak: 0.0), type: .power)
          LevelIndicatorView(levels: SignalLevel(rms: 1.0, peak: 0.0), type: .swr)
        }
        PowerView(transmit: apiModel.transmit)
        ProfileView(txProfile: apiModel.profiles[id: "tx"] ?? Profile("empty", apiModel))
        AtuStatusView(atu: apiModel.atu)
      }
      VStack(alignment: .center, spacing: 10) {
        ButtonsView(transmit: apiModel.transmit, radio: apiModel.radio ?? Radio(Packet(), apiModel), atu: apiModel.atu)
        Divider().background(.blue)
      }
    }
  }
}

private struct PowerView: View {
  var transmit: Transmit

  public var body: some View {
    VStack(spacing: 5) {
      HStack(spacing: 10) {
        Text("Rf Power").frame(width: 75, alignment: .leading)
        HStack(spacing: 20) {
          Text("\(transmit.rfPower)").frame(width: 25, alignment: .trailing)
          Slider(value: Binding(get: { Double(transmit.rfPower) }, set: { transmit.setProperty(.rfPower, String(Int($0))) }), in: 0...100, step: 1)
        }
      }
      HStack(spacing: 10) {
        Text("Tune Power").frame(width: 75, alignment: .leading)
        HStack(spacing: 20) {
          Text("\(transmit.tunePower)").frame(width: 25, alignment: .trailing)
          Slider(value: Binding(get: { Double(transmit.tunePower) }, set: { transmit.setProperty(.tunePower, String(Int($0))) }), in: 0...100, step: 1)
        }
      }
    }
  }
}

private struct ProfileView: View {
  var txProfile: Profile

  public var body: some View {
    HStack(spacing: 25) {
      Picker("", selection: Binding(
        get: { txProfile.current },
        set: { txProfile.setProperty("load", $0) })) {
          ForEach(txProfile.list, id: \.self) {
          Text($0).tag($0)
        }
      }
      .labelsHidden()
      .pickerStyle(.menu)
      .frame(width: 200, alignment: .leading)
      
      Button("Save", action: {})
        .font(.footnote)
        .buttonStyle(BorderlessButtonStyle())
        .foregroundColor(.blue)
    }
  }
}

private struct AtuStatusView: View {
  var atu: Atu
  
  public var body: some View {
    HStack(spacing: 20) {
      Toggle(isOn: Binding(
        get: { atu.enabled },
        set: { atu.setProperty(.enabled, $0.as1or0) })) { Text("ATU").frame(width: 40) }
        .toggleStyle(.button)
      
      Text(atu.status.rawValue).frame(width: 180)
        .border(.secondary)
    }
  }
}

private struct ButtonsView: View {
  var transmit: Transmit
  var radio: Radio
  var atu: Atu

  public var body: some View {
    HStack(spacing: 45) {
      Group {
        Toggle(isOn: Binding(
          get: { atu.memoriesEnabled },
          set: { atu.setProperty(.memoriesEnabled, $0.as1or0) })) { Text("MEM").frame(width: 40) }
        Toggle(isOn: Binding(
          get: { transmit.tune },
          set: { transmit.setProperty(.tune, $0.as1or0) } )) { Text("TUNE").frame(width: 40) }
        Toggle(isOn: Binding(
          get: { radio.mox },
          set: { transmit.setProperty(.mox, $0.as1or0) } )) { Text("MOX").frame(width: 40) }
      }
      .toggleStyle(.button)
    }
  }
}

#Preview {
  TxView()
    .frame(width: 275)
}
