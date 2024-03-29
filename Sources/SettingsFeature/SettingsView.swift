//
//  SettingsView.swift
//  SettingsFeature/SettingsFeature
//
//
//  Created by Douglas Adams on 12/21/22.
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  
  public var body: some View {
    
    TabView(selection: $store.tabSelection) {
      Group {
        GpsView(store: store)
          .tabItem {
            Text(TabSelection.gps.rawValue)
            Image(systemName: "globe")
          }.tag(TabSelection.gps.rawValue)
        
        ColorsView(store: store)
          .tabItem {
            Text(TabSelection.colors.rawValue)
            Image(systemName: "eyedropper")
          }.tag(TabSelection.colors.rawValue)
        
        XvtrView(store: store)
          .tabItem {
            Text(TabSelection.xvtrs.rawValue)
            Image(systemName: "arrow.up.arrow.down.circle")
          }.tag(TabSelection.xvtrs.rawValue)
        
        MiscView(store: store)
          .tabItem {
            Text(TabSelection.misc.rawValue)
            Image(systemName: "gear")
          }.tag(TabSelection.misc.rawValue)

        ConnectionView(store: store)
          .tabItem {
            Text(TabSelection.connection.rawValue)
            Image(systemName: "list.bullet")
          }.tag(TabSelection.connection.rawValue)
      }
      
      Group {
        NetworkView(store: store)
          .tabItem {
            Text(TabSelection.misc.rawValue)
            Image(systemName: "wifi")
          }.tag(TabSelection.misc.rawValue)

        RadioView(store: store)
          .tabItem {
            Text(TabSelection.radio.rawValue)
            Image(systemName: "antenna.radiowaves.left.and.right")
          }.tag(TabSelection.radio.rawValue)

        TxView(store: store)
          .tabItem {
            Text(TabSelection.tx.rawValue)
            Image(systemName: "bolt.horizontal")
          }.tag(TabSelection.tx.rawValue)
        
        ProfilesView(store: store)
          .tabItem {
            Text(TabSelection.profiles.rawValue)
            Image(systemName: "brain.head.profile")
          }.tag(TabSelection.profiles.rawValue)
        
        PhoneCwView(store: store)
          .tabItem {
            Text(TabSelection.phoneCw.rawValue)
            Image(systemName: "mic")
          }.tag(TabSelection.phoneCw.rawValue)
      }
    }
    .frame(width: 600, height: 350)
    .padding()
  }
}

          

//      Group {
//      }
//    }
//    .onDisappear {
//      // close the ColorPicker (if open)
//      if NSColorPanel.shared.isVisible {
//        NSColorPanel.shared.performClose(nil)
//      }
//    }

#Preview {
  SettingsView(store: Store(initialState: SettingsFeature.State() ) {
    SettingsFeature()
  })
  .frame(width: 600, height: 350)
  .padding()
}
