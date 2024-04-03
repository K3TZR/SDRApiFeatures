//
//  MiscView.swift
//
//
//  Created by Douglas Adams on 3/1/23.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

struct MiscView: View {
  @Bindable var store: StoreOf<SettingsCore>
  
  var body: some View {

    VStack {
      Picker("Monitor meter", selection: $store.monitorShortName) {
        ForEach(Meter.ShortName.allCases, id: \.self) { shortName in
          Text(shortName.rawValue).tag(shortName.rawValue)
        }
      }
      .labelsHidden()
      .pickerStyle(.menu)
      .frame(width: 100, alignment: .leading)
      
      Spacer()
      Toggle("Log Broadcasts", isOn: $store.logBroadcasts)
      Toggle("Ignore TimeStamps", isOn: $store.ignoreTimeStamps)
      Toggle("Alert on Error / Warning", isOn: $store.alertOnError)
      
      Spacer()
      
//      VStack {
//        Text("Custom Antenna Names")
//        Divider()
//        Grid (verticalSpacing: 10) {
//          ForEach(apiModel.antList, id: \.self) { antenna in
//            GridRow {
//              Text(antenna)
//              ApiStringView(value: apiModel.altAntennaName(for: antenna), action: { apiModel.altAntennaName(for: antenna, $0) })
//            }.frame(width: 120)
//          }
//        }
//      }.frame(width: 200)
//      Spacer()
    }
  }
}

#Preview {
  MiscView(store: Store(initialState: SettingsCore.State()) {
    SettingsCore()
  })
  
  .frame(width: 600, height: 350)
  .padding()
}
