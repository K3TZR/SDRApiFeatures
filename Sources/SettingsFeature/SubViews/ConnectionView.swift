//
//  ConnectionView.swift
//  
//
//  Created by Douglas Adams on 6/12/23.
//

import ComposableArchitecture
import SwiftUI

import SharedFeature

struct ConnectionView: View {
  @Bindable var store: StoreOf<SettingsFeature>
  
  var body: some View {

    VStack(alignment: .leading) {
      HeadingView(store: store)
      Spacer()
      Divider().background(Color.blue)
      Spacer()
      ListHeadingView()
      Divider()
      ListView(store: store)
        .frame(height: 200)
    }
  }
}

private struct HeadingView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  public var body: some View {

    Grid(alignment: .leading, horizontalSpacing: 40){
        
      GridRow {
        Text("Station")
        TextField("Station name", text: $store.stationName)
          .multilineTextAlignment(.trailing)
          .frame(width: 100)
        Toggle("Use Default radio", isOn: $store.useDefault)
        Toggle("Login required", isOn: $store.loginRequired)
      }
      GridRow {
        Text("MTU")
        TextField("MTU value", value: $store.mtuValue, format: .number)
          .multilineTextAlignment(.trailing)
          .frame(width: 100)
        Toggle("RemoteRxAudio Compressed", isOn: $store.remoteRxAudioCompressed)
        Toggle("Reduced DAX BW", isOn: $store.daxReducedBandwidth)
      }
    }
  }
}

private struct ListHeadingView: View {

  public var body: some View {

    HStack {
      Spacer()
      Text("Direct Connect Radios").font(.title2).bold()
      Spacer()
    }
    HStack {
      Group {
        Text("Name")
        Text("IP Address")
      }
      .frame(width: 180, alignment: .leading)
    }
  }
}

private struct ListView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  @State var selection: UUID?

  private func add(_ radio: KnownRadio) {
    store.knownRadios.append(radio)
  }

  private func delete(_ radio: KnownRadio) {
    store.knownRadios.remove(at: store.knownRadios.firstIndex(of: radio)!)
  }

  public var body: some View {

    VStack(alignment: .leading) {
      List($store.knownRadios, selection: $selection) { knownRadio in
        HStack {
          Group {
            TextField("Name", text: knownRadio.name)
            TextField("IP Address", text: knownRadio.ipAddress)
          }
          .frame(width: 180, alignment: .leading)
        }
      }
      
      Divider()
      
      HStack (spacing: 40) {
        Spacer()
        Button("Add") { add(KnownRadio("New Radio", "", "")) }
        Button("Delete") {
          for knownRadio in store.knownRadios where knownRadio.id == selection {
            delete(knownRadio)
          }
        }.disabled(selection == nil)
      }
      Spacer()
    }

  }
}

#Preview {
  ConnectionView(store: Store(initialState: SettingsFeature.State()) {
    SettingsFeature()
  })
  .frame(width: 600, height: 350)
  .padding()
}
