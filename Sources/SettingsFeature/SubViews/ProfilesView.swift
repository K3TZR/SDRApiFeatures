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

  @Environment(ObjectModel.self) var objectModel
  
  var body: some View {

    if objectModel.profiles.count > 0 {
      ForEach(objectModel.profiles) { profile in
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
            set: {_,_ in profile.set("load", "mic") } ))
          Toggle("TX", isOn: Binding(
            get: { profile.id == ProfileSelection.tx.rawValue},
            set: {_,_ in profile.set("load", "tx") } ))
          Toggle("GLOBAL", isOn: Binding(
            get: { profile.id == ProfileSelection.global.rawValue},
            set: {_,_ in profile.set("load", "global") } ))
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
        Button("New") { profile.set("create", "A New Profile") }
        Group {
          Button("Delete") { profile.set("delete", selection!) }
          Button("Reset") { profile.set("reset", selection!) }
          Button("Load") { profile.set("load", selection!) }
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
  
  .environment(ObjectModel())
  
  .frame(width: 600, height: 350)
  .padding()
}
