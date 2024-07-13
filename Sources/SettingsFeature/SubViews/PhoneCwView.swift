//
//  PhoneCwView.swift
//  ViewFeatures/SettingsFeature/PhoneCw
//
//  Created by Douglas Adams on 5/13/21.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

struct PhoneCwView: View {
  var store: StoreOf<SettingsCore>
  
  @Environment(ObjectModel.self) var objectModel

  var body: some View {

    if objectModel.radio == nil {
      VStack {
        Text("Radio must be connected").font(.title).foregroundColor(.red)
        Text("to use PhoneCw Settings").font(.title).foregroundColor(.red)
      }
      
    } else {
      VStack(spacing: 10) {
        Group {
          MicGridView(transmit: objectModel.transmit)
          Spacer()
          Divider().foregroundColor(.blue)
        }
        Group {
          Spacer()
          CwGridView(transmit: objectModel.transmit)
          Spacer()
          Divider().foregroundColor(.blue)
        }
        Group {
          Spacer()
          RttyGridView(radio: objectModel.radio!)
          Spacer()
          Divider().foregroundColor(.blue)
        }
        Group {
          Spacer()
          FiltersGridView(radio: objectModel.radio!)
          Spacer()
        }
      }
    }
  }
}

private struct MicGridView: View {
  var transmit: Transmit

  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 80, verticalSpacing: 20) {
      GridRow() {
        Toggle("Microphone bias", isOn: Binding(
          get: { transmit.micBiasEnabled },
          set: { transmit.set(.micBiasEnabled, $0.as1or0) } ))
        Toggle("Mic level during receive", isOn: Binding(
          get: { transmit.meterInRxEnabled },
          set: { transmit.set(.meterInRxEnabled, $0.as1or0) } ))
        Toggle("+20 db Mic gain", isOn: Binding(
          get: { transmit.micBoostEnabled },
          set: { transmit.set(.micBoostEnabled, $0.as1or0) } ))
      }
    }
  }
}

private struct CwGridView: View {
  var transmit: Transmit

  private let iambicModes = ["A", "B"]
  private let cwSidebands = ["Upper", "Lower"]

  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 60, verticalSpacing: 20) {
      GridRow() {
        Toggle("Iambic", isOn: Binding(
          get: { transmit.cwIambicEnabled },
          set: { transmit.set(.cwIambicEnabled, $0.as1or0) } ))

        Picker("", selection: Binding(
          get: { transmit.cwIambicMode ? "B" : "A"},
          set: { transmit.set(.cwIambicMode, ($0 == "B").as1or0) } )) {
            ForEach(iambicModes, id: \.self) {
              Text($0).tag($0)
            }
          }
          .labelsHidden()
          .pickerStyle(.segmented)
          .frame(width: 110)

        Toggle("Swap dot / dash", isOn: Binding(
          get: { transmit.cwSwapPaddles },
          set: { transmit.set(.cwSwapPaddles, $0.as1or0) } ))

        Toggle("CWX sync", isOn: Binding(
          get: { transmit.cwSyncCwxEnabled },
          set: { transmit.set(.cwSyncCwxEnabled, $0.as1or0) } ))
      }

      GridRow {
        Text("CW Sideband")
        Picker("", selection: Binding(
          get: { transmit.cwlEnabled ? "Lower" : "Upper" },
          set: { transmit.set(.cwlEnabled, ($0 == "Lower").as1or0) } )) {
            ForEach(cwSidebands, id: \.self) {
              Text($0).tag($0)
            }
          }
          .labelsHidden()
          .pickerStyle(.segmented)
          .frame(width: 110)
      }
    }
  }
}

private struct FiltersGridView: View {
  var radio: Radio

  var body: some View {
    Grid(horizontalSpacing: 20, verticalSpacing: 5) {
      GridRow() {
        Text("Voice")
        Text(radio.filterVoiceLevel, format: .number).frame(width: 20).multilineTextAlignment(.trailing)
        Slider(value: Binding(
          get: {  Double(radio.filterVoiceLevel) },
          set: { radio.setFilter(.voice, .level, String(Int($0))) }), in: 0...3, step: 1).frame(width: 250)
        Toggle("Auto", isOn: Binding(
          get: { radio.filterVoiceAutoEnabled },
          set: { radio.setFilter(.voice, .autoLevel, $0.as1or0) }))
      }
      GridRow() {
        Text("CW")
        Text(radio.filterCwLevel, format: .number).frame(width: 20).multilineTextAlignment(.trailing)
        Slider(value: Binding(
          get: { Double(radio.filterCwLevel) },
          set: { radio.setFilter(.cw, .level, String(Int($0))) }), in: 0...3, step: 1).frame(width: 250)
        Toggle("Auto", isOn: Binding(
          get: { radio.filterCwAutoEnabled },
          set: { radio.setFilter(.cw, .autoLevel, $0.as1or0) }))
      }
      GridRow() {
        Text("Digital")
        Text(radio.filterDigitalLevel, format: .number).frame(width: 20).multilineTextAlignment(.trailing)
        Slider(value: Binding(
          get: { Double(radio.filterDigitalLevel) },
          set: { radio.setFilter(.digital, .level, String(Int($0))) }), in: 0...3, step: 1).frame(width: 250)
        Toggle("Auto", isOn: Binding(
          get: { radio.filterDigitalAutoEnabled },
          set: { radio.setFilter(.digital, .autoLevel, $0.as1or0) }))
      }
    }
  }
}

private struct RttyGridView: View {
  var radio: Radio

  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 20) {
      GridRow() {
        Text("RTTY Mark default").frame(width: 115, alignment: .leading)
//        ApiIntView(value: radio.rttyMark, action: { _ in radio.set(.rttyMark, String(radio.rttyMark)) } )
      }
    }
  }
}

#Preview {
  PhoneCwView(store: Store(initialState: SettingsCore.State()) {
    SettingsCore()
  })
  
  .environment(ObjectModel.shared)
  
  .frame(width: 600, height: 350)
  .padding()
}
