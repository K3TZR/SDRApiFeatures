//
//  Gpsiew.swift
//  ViewFeatures/SettingsFeature/Gps
//
//  Created by Douglas Adams on 5/13/21.
//

import ComposableArchitecture
import SwiftUI

struct GpsView: View {
  var store: StoreOf<SettingsCore>
  
  var body: some View {
    Text("GPS View not implemented").font(.title).foregroundColor(.red)
  }
}

#Preview {
  GpsView(store: Store(initialState: SettingsCore.State() ) {
    SettingsCore()
  })
  
  .frame(width: 600, height: 350)
  .padding()
}
