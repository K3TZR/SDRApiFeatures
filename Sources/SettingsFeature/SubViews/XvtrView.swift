//
//  XvtrView.swift
//  SettingsFeature/Xvtr
//
//  Created by Douglas Adams on 5/13/21.
//

import ComposableArchitecture
import SwiftUI

struct XvtrView: View {
  var store: StoreOf<SettingsCore>
  
  var body: some View {
    Text("Xvtr View not implemented").font(.title).foregroundColor(.red)
      .frame(width: 600, height: 400)
      .padding()
  }
}

#Preview {
  XvtrView(store: Store(initialState: SettingsCore.State() ) {
    SettingsCore()
  })
  
  .frame(width: 600, height: 350)
  .padding()
}
