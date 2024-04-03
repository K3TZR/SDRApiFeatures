//
//  ProfilesView.swift
//  ViewFeatures/SettingsFeature/Profiles
//
//  Created by Douglas Adams on 12/30/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

struct ProfilesView: View {
  var store: StoreOf<SettingsCore>

  @Environment(ApiModel.self) var apiModel
  
  var body: some View {

    if apiModel.profiles.count > 0 {
      ForEach(apiModel.profiles) { profile in
        if store.profileSelection == profile.id {
          ProfileView(profile: profile)
        }
      }
    } else {
      VStack {
        Text("Radio must be connected").font(.title).foregroundColor(.red)
        Text("to use Profile Settings").font(.title).foregroundColor(.red)
      }
    }
  }
}

private struct ProfileView: View {
  @Bindable var profile: Profile
  
  @State private var selection: String?
  @State private var newProfileName = ""
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 40) {
        ControlGroup {
          Toggle("MIC", isOn: Binding(
            get: { profile.id == ProfileSelection.mic.rawValue},
            set: {_,_ in profile.setProperty("load", "mic") } ))
          Toggle("TX", isOn: Binding(
            get: { profile.id == ProfileSelection.tx.rawValue},
            set: {_,_ in profile.setProperty("load", "tx") } ))
          Toggle("GLOBAL", isOn: Binding(
            get: { profile.id == ProfileSelection.global.rawValue},
            set: {_,_ in profile.setProperty("load", "global") } ))
        }
      }
      .font(.title)
      .foregroundColor(.blue)
      
      List($profile.list, id: \.self, selection: $selection) { $name in
        TextField("Name", text: $name).tag(name)
          .foregroundColor(profile.current == name ? .red : nil)
      }
      Divider().foregroundColor(.blue)
      
      HStack {
        Spacer()
        Button("New") { profile.setProperty("create", "A New Profile") }
        Group {
          Button("Delete") { profile.setProperty("delete", selection!) }
          Button("Reset") { profile.setProperty("reset", selection!) }
          Button("Load") { profile.setProperty("load", selection!) }
        }.disabled(selection == nil)
        Spacer()
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  ProfilesView(store: Store(initialState: SettingsCore.State() ) {
    SettingsCore()
  })
  .environment(ApiModel.shared)
  
  .frame(width: 600, height: 350)
  .padding()
}
