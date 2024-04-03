//
//  SettingsView.swift
//  SettingsFeature/SettingsFeature
//
//
//  Created by Douglas Adams on 12/21/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

public struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsCore>

  public init(store: StoreOf<SettingsCore>) {
    self.store = store
  }
  
  public var body: some View {
    
    TabView(selection: $store.tabSelection) {
      Group {
        RadioView(store: store)
          .tabItem {
            Label(TabSelection.radio.rawValue, systemImage: "antenna.radiowaves.left.and.right")
          }.tag(TabSelection.radio.rawValue)

        NetworkView(store: store)
          .tabItem {
            Label(TabSelection.network.rawValue, systemImage: "wifi")
          }.tag(TabSelection.network.rawValue)

        GpsView(store: store)
          .tabItem {
            Label(TabSelection.gps.rawValue, systemImage: "globe")
          }.tag(TabSelection.gps.rawValue)
        
        TxView(store: store)
          .tabItem {
            Label(TabSelection.tx.rawValue, systemImage: "bolt.horizontal")
          }.tag(TabSelection.tx.rawValue)
        
        PhoneCwView(store: store)
          .tabItem {
            Label(TabSelection.phoneCw.rawValue, systemImage: "mic")
          }.tag(TabSelection.phoneCw.rawValue)

      }
      
      Group {
        XvtrView(store: store)
          .tabItem {
            Label(TabSelection.xvtrs.rawValue, systemImage: "arrow.up.arrow.down.circle")
          }.tag(TabSelection.xvtrs.rawValue)
        
        ProfilesView(store: store)
          .tabItem {
            Label(TabSelection.profiles.rawValue, systemImage: "brain.head.profile")
          }.tag(TabSelection.profiles.rawValue)
        
        ConnectionView(store: store)
          .tabItem {
            Label(TabSelection.connection.rawValue, systemImage: "list.bullet")
          }.tag(TabSelection.connection.rawValue)

        ColorsView(store: store)
          .tabItem {
            Label(TabSelection.colors.rawValue, systemImage: "eyedropper")
          }.tag(TabSelection.colors.rawValue)

        MiscView(store: store)
          .tabItem {
            Label(TabSelection.misc.rawValue, systemImage: "gear")
          }.tag(TabSelection.misc.rawValue)
      }
    }
    .frame(width: 600, height: 390)
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
  SettingsView(store: Store(initialState: SettingsCore.State() ) {
    SettingsCore()
  })
  .environment(ApiModel.shared)
  
  .frame(width: 600, height: 390)
  .padding()
}
