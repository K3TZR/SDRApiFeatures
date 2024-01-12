//
//  ClientFeature.swift
//  ViewFeatures/ClientFeature
//
//  Created by Douglas Adams on 1/19/22.
//

import ComposableArchitecture
import SwiftUI

import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View(s)

// assumes that the number of GuiClients is 1 or 2

public struct ClientView: View {
  var store: StoreOf<ClientFeature>
  
  public init(store: StoreOf<ClientFeature>) {
    self.store = store
  }
  
  @Environment(\.dismiss) var dismiss
  
  public var body: some View {
    VStack(spacing: 20) {
      Text(store.heading).font(.title)
      Divider().background(Color.blue)
      
      if store.guiClients.count == 1 {
        Button("MultiFlex connect") {
          store.send(.connect(store.selection, nil))
          dismiss()
        }
        .frame(width: 150) }
      
      ForEach(store.guiClients) { guiClient in
        Button("Close " + guiClient.station) {
          store.send(.connect(store.selection, guiClient.handle))
          dismiss()
        }
        .frame(width: 150)
      }
      
      Divider().background(Color.blue)
      
      Button("Cancel") {
        dismiss()
      }
      .keyboardShortcut(.cancelAction)
    }
    .frame(width: 250)
    .padding()
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

#Preview("Gui connect (disconnect not required)") {
  ClientView(store: Store(initialState: ClientFeature.State(selection: "", guiClients: IdentifiedArrayOf<GuiClient>(arrayLiteral: GuiClient(handle: 1, station: "Station_1")))) {
    ClientFeature()
  })
}

#Preview("Gui connect (disconnect required)") {
  ClientView(store: Store(initialState: ClientFeature.State(selection: "", guiClients: IdentifiedArrayOf<GuiClient>(arrayLiteral: GuiClient(handle: 1, station: "Station_1"), GuiClient(handle: 2, station: "Station_2")))) {
    ClientFeature()
  })
}
