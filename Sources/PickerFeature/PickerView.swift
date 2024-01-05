//
//  PickerView.swift
//  ViewFeatures/PickerFeature
//
//  Created by Douglas Adams on 11/13/21.
//

import ComposableArchitecture
import SwiftUI

import ListenerFeature

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct PickerView: View {
  let store: StoreOf<PickerFeature>
  
  public init(store: StoreOf<PickerFeature>) {
    self.store = store
  }
  @State var selection: String?
  
  @MainActor private var isSmartlink: Bool {
    if let selection {
      if store.isGui {
        return store.listener.packets[id: selection]?.source == .smartlink
      } else {
        return store.listener.stations[id: selection]?.packet.source == .smartlink
      }
    }
    return false
  }

  public var body: some View {
    VStack(alignment: .leading) {
      HeaderView(store: store)
      
      Divider()
      if store.isGui && store.listener.packets.count == 0 || !store.isGui && store.listener.stations.count == 0{
        VStack {
          HStack {
            Spacer()
            Text("----------  NO \(store.isGui ? "RADIOS" : "STATIONS") FOUND  ----------")
            Spacer()
          }
        }
        .foregroundColor(.red)
        .frame(minHeight: 150)
        .padding(.horizontal)
        
      } 
      else {
        if store.isGui {
          // ----- List of Radios -----
          List(store.listener.packets, id: \.id, selection: $selection) { packet in
            //            VStack (alignment: .leading) {
            HStack(spacing: 0) {
              Group {
                Text(packet.nickname)
                Text(packet.source.rawValue)
                Text(packet.status)
                Text(packet.guiClientStations)
              }
              .font(.title3)
              .foregroundColor(store.guiDefault == packet.serial + packet.publicIp ? .red : nil)
              .frame(minWidth: 140, alignment: .leading)
            }
            //            }
          }
          .frame(minHeight: 150)
          .padding(.horizontal)
          
        } else {
          // ----- List of Stations -----
          List(store.listener.stations, id: \.id, selection: $selection) { station in
            //            VStack (alignment: .leading) {
            HStack(spacing: 0) {
              Group {
                Text(station.packet.nickname)
                Text(station.packet.source.rawValue)
                Text(station.packet.status)
                Text(station.station)
              }
              .font(.title3)
              .foregroundColor(store.nonGuiDefault == station.packet.serial + station.packet.publicIp + station.station ? .red : nil)
              .frame(minWidth: 140, alignment: .leading)
            }
            //            }
          }
          .frame(minHeight: 150)
          .padding(.horizontal)
        }
      }
    }
    Divider()
    FooterView(store: store, selection: selection, selectionIsSmartlink: isSmartlink)
  }
}

private struct HeaderView: View {
  let store: StoreOf<PickerFeature>

  var body: some View {
    VStack {
      Text("Select a \(store.isGui ? "RADIO" : "STATION")")
        .font(.title)
        .padding(.bottom, 10)
      
      HStack(spacing: 0) {
        Group {
          Text("Name")
          Text("Type")
          Text("Status")
          Text("Station\(store.isGui ? "s" : "")")
        }
        .frame(width: 140, alignment: .leading)
      }
    }
    .font(.title2)
    .padding(.vertical, 10)
    .padding(.horizontal)
  }
}

private struct FooterView: View {
  let store: StoreOf<PickerFeature>
  let selection: String?
  let selectionIsSmartlink: Bool

  @Environment(\.dismiss) var dismiss

  var body: some View {
    
    HStack(){
      Button("Test") { store.send(.testButtonTapped(selection!)) }
        .disabled(!selectionIsSmartlink)
      Circle()
        .fill(store.testResult ? Color.green : Color.red)
        .frame(width: 20, height: 20)
      
      Spacer()
      Button("Default") {
        store.send(.defaultButtonTapped(selection!))
      }
      .disabled(selection == nil)
      
      Spacer()
      Button("Cancel") {
        dismiss()
      }
      .keyboardShortcut(.cancelAction)
      
      Spacer()
      Button("Connect") {
        store.send(.connectButtonTapped(selection!))
        dismiss()
      }
      .keyboardShortcut(.defaultAction)
      .disabled(selection == nil)
    }
    .padding(.vertical, 10)
    .padding(.horizontal)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview("Picker Gui") {
  PickerView(store: Store(initialState: PickerFeature.State(isGui: true, listener: Listener(previousIdToken: nil), guiDefault: nil, nonGuiDefault: nil)) {
    PickerFeature()
  })
}
#Preview("Picker NON-Gui") {
  PickerView(store: Store(initialState: PickerFeature.State(isGui: false, listener: Listener(previousIdToken: nil), guiDefault: nil, nonGuiDefault: nil)) {
    PickerFeature()
  })
}
