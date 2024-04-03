//
//  ColorsView.swift
//  ViewFeatures/SettingsFeature/Colors
//
//  Created by Douglas Adams on 5/13/21.
//

import ComposableArchitecture
import SwiftUI

struct ColorsView: View {
  @Bindable var store: StoreOf<SettingsCore>
    
  var body: some View {

    VStack {
      Grid(alignment: .leading, horizontalSpacing: 35, verticalSpacing: 15) {
        GridRow() {
          Text("Spectrum")
          ColorPicker("", selection: $store.spectrumLine).labelsHidden()
          Button("Reset") { store.send(.reset("spectrumLine")) }
          
          Text("Spectrum Fill")
          ColorPicker("", selection: $store.spectrumFill).labelsHidden()
          Button("Reset") { store.send(.reset("spectrumFill")) }
        }
        GridRow() {
          Text("Freq Legend")
          ColorPicker("", selection: $store.frequencyLegend).labelsHidden()
          Button("Reset") { store.send(.reset("frequencyLegend")) }
          
          Text("Db Legend")
          ColorPicker("", selection: $store.dbLegend).labelsHidden()
          Button("Reset") { store.send(.reset("dbLegend")) }
        }
        GridRow() {
          Text("Grid lines")
          ColorPicker("", selection: $store.gridLines).labelsHidden()
          Button("Reset") { store.send(.reset("gridLines")) }
          
          Text("Db lines")
          ColorPicker("", selection: $store.dbLines).labelsHidden()
          Button("Reset") { store.send(.reset("dbLines")) }
        }
        GridRow() {
          Text("Marker edge")
          ColorPicker("", selection: $store.markerEdge).labelsHidden()
          Button("Reset") { store.send(.reset("markerEdge")) }
          
          Text("Marker segment")
          ColorPicker("", selection: $store.markerSegment).labelsHidden()
          Button("Reset") { store.send(.reset("markerSegment")) }
        }
        GridRow() {
          Text("Slice filter")
          ColorPicker("", selection: $store.sliceFilter).labelsHidden()
          Button("Reset") { store.send(.reset("sliceFilter")) }
          
          Text("Marker")
          ColorPicker("", selection: $store.marker).labelsHidden()
          Button("Reset") { store.send(.reset("marker")) }
        }
        GridRow() {
          Text("Tnf (Inactive)")
          ColorPicker("", selection: $store.tnfInactive).labelsHidden()
          Button("Reset") { store.send(.reset("tnfInactive")) }
          
          Text("Tnf (normal)")
          ColorPicker("", selection: $store.tnfNormal).labelsHidden()
          Button("Reset") { store.send(.reset("tnfNormal")) }
        }
        GridRow() {
          Text("Tnf (deep)")
          ColorPicker("", selection: $store.tnfDeep).labelsHidden()
          Button("Reset") { store.send(.reset("tnfDeep")) }
          
          Text("Tnf (very deep)")
          ColorPicker("", selection: $store.tnfVeryDeep).labelsHidden()
          Button("Reset") { store.send(.reset("tnfVeryDeep")) }
        }
        GridRow() {
          Text("Tnf (permanent)")
          ColorPicker("", selection: $store.tnfPermanent).labelsHidden()
          Button("Reset") { store.send(.reset("tnfPermanent")) }
          
          Text("Background")
          ColorPicker("", selection: $store.background).labelsHidden()
          Button("Reset") { store.send(.reset("background")) }
        }
        GridRow() {
          Text("Slice (active)")
          ColorPicker("", selection: $store.sliceActive).labelsHidden()
          Button("Reset") { store.send(.reset("sliceActive")) }
          
          Text("Slice (Inactive)")
          ColorPicker("", selection: $store.sliceInactive).labelsHidden()
          Button("Reset") { store.send(.reset("sliceInactive")) }
        }
      }
      Divider().background(Color.blue)
      HStack {
        Spacer()
        Button("Reset All") { store.send(.resetAll) }
        Spacer()
      }
    }
  }
}

#Preview {
  ColorsView(store: Store(initialState: SettingsCore.State() ) {
    SettingsCore()
  })
  
  .frame(width: 600, height: 350)
  .padding()
}

