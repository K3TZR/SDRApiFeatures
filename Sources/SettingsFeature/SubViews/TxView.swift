//
//  TxView.swift
//  SettingsFeature/TxFeature
//
//  Created by Douglas Adams on 5/13/21.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

struct TxView: View {
  @Bindable var store: StoreOf<SettingsCore>
  
  @Environment(ObjectModel.self) var objectModel

  var body: some View {

    if objectModel.clientInitialized {
      VStack {
//        Group {
          InterlocksGridView(interlock: objectModel.interlock)
          Spacer()
          Divider().foregroundColor(.blue)
//        }
//        Group {
//          Spacer()
          TxGridView(interlock: objectModel.interlock,
                     txProfile: objectModel.profiles[id: "tx"] ?? Profile("tx", ObjectModel.shared),
                     transmit: objectModel.transmit
          )
//          Spacer()
//        }
      }
    } else {
      VStack {
        Text("Radio must be connected").font(.title).foregroundColor(.red)
        Text("to use Tx Settings").font(.title).foregroundColor(.red)
      }
    }
  }
}

private struct InterlocksGridView: View {
  var interlock: Interlock
  
  private let interlockLevels = ["Disabled", "Active High", "Active Low"]
  
  let width: CGFloat = 100
  
  @MainActor var rcaSelection: Int {
    guard interlock.rcaTxReqEnabled else { return 0 }
    return interlock.rcaTxReqPolarity ? 1 : 2
  }
  @MainActor var accSelection: Int {
    guard interlock.accTxReqEnabled else { return 0 }
    return interlock.accTxReqPolarity ? 1 : 2
  }
  
  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 200, verticalSpacing: 20) {
      
      GridRow() {
        Picker("RCA", selection: Binding(
          get: { interlockLevels[rcaSelection] },
          set: { interlock.set(.rcaTxReqEnabled, $0) } )) {
            ForEach(interlockLevels, id: \.self) {
              Text($0).tag($0)
            }
          }
          .pickerStyle(.menu)
          .frame(width: 180)

        Picker("ACC", selection: Binding(
          get: { interlockLevels[accSelection]  },
          set: { interlock.set(.accTxReqEnabled, $0) } )) {
            ForEach(interlockLevels, id: \.self) {
              Text($0).tag($0)
            }
          }
          .pickerStyle(.menu)
          .frame(width: 180)

      }
      GridRow() {
        HStack {
          Toggle("RCA TX1", isOn: Binding(
            get: { interlock.tx1Enabled },
            set: { interlock.set(.tx1Enabled, $0.as1or0) } ))
//          ApiIntView(hint: "tx1 delay", value: interlock.tx1Delay, action: { interlock.setProperty(.tx1Delay, $0) })
        }
        
        HStack {
          Toggle("ACC TX", isOn: Binding(
            get: { interlock.accTxEnabled },
            set: { interlock.set(.accTxEnabled, $0.as1or0) } ))
//          ApiIntView(hint: "acc delay", value: interlock.accTxDelay, action: { interlock.setProperty(.accTxDelay, $0) })
        }
      }.frame(width: 180)
      
      GridRow() {
        HStack {
          Toggle("RCA TX2", isOn: Binding(
            get: { interlock.tx2Enabled},
            set: { interlock.set(.tx2Enabled, $0.as1or0) } ))
//          ApiIntView(hint: "tx2 delay", value: interlock.tx2Delay, action: { interlock.setProperty(.tx2Delay, $0) })
        }
        HStack {
          Text("TX Delay").frame(width: 65, alignment: .leading)
//          ApiIntView(hint: "tx delay", value: interlock.txDelay, action: { interlock.setProperty(.txDelay, $0) })
        }
      }.frame(width: 180)
      
      GridRow() {
        HStack {
          Toggle("RCA TX3", isOn: Binding(
            get: { interlock.tx3Enabled},
            set: { interlock.set(.tx3Enabled, $0.as1or0) } ))
//          ApiIntView(hint: "tx3 delay", value: interlock.tx3Delay, action: { interlock.setProperty(.tx3Delay, $0) } )
        }
        HStack {
          Text("Timeout (min)")
//          ApiIntView(value: interlock.timeout, action: { interlock.set(.timeout, $0) })
        }
      }.frame(width: 180)
    }
  }
}

private struct TxGridView: View {
  var interlock: Interlock
  var txProfile: Profile
  var transmit: Transmit
  
  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 40, verticalSpacing: 20) {
      
      GridRow() {
        Toggle("TX Inhibit", isOn: Binding(
          get: { transmit.inhibit },
          set: { transmit.set(.inhibit, $0.as1or0) } ))
        .toggleStyle(.checkbox)
        Toggle("TX in Waterfall", isOn: Binding(
          get: { transmit.txInWaterfallEnabled},
          set: { transmit.set(.txInWaterfallEnabled, $0.as1or0) } ))
        .toggleStyle(.checkbox)
        Text("Tx Profile")
        Picker("", selection: Binding(
          get: { txProfile.current},
          set: { txProfile.set("load", $0) })) {
            ForEach(txProfile.list, id: \.self) {
              Text($0).tag($0)
            }
          }
          .labelsHidden()
          .pickerStyle(.menu)
          .frame(width: 180)
      }
      GridRow() {
        Text("Max Power")
        HStack {
          Text("\(String(format: "%3d", transmit.maxPowerLevel))")
          Slider(value: Binding(
            get: { Double(transmit.maxPowerLevel) },
            set: { transmit.set(.maxPowerLevel, String(Int($0))) } ), in: 0...100, step: 1).frame(width: 150)
        }.gridCellColumns(2)
        Toggle("Hardware ALC", isOn: Binding(
          get: { transmit.hwAlcEnabled},
          set: { transmit.set(.hwAlcEnabled, $0.as1or0) } ))
      }
    }
  }
}

#Preview {
  TxView(store: Store(initialState: SettingsCore.State()) {
    SettingsCore()
  })
  
  .environment(ObjectModel.shared)

  .frame(width: 600, height: 350)
  .padding()
}
