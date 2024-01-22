//
//  GuiClientSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import ListenerFeature
import SettingsFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct GuiClientSubView: View {
  let store: StoreOf<ObjectsFeature>
    
  @Environment(Listener.self) private var listener

  var body: some View {
    VStack(alignment: .leading) {
      if listener.activePacket != nil {
        ForEach(listener.activePacket!.guiClients, id: \.id) { guiClient in
          DetailView(guiClient: guiClient)
        }
      } else {
        Text("No active packet")
      }
    }
  }
}

private struct DetailView: View {
  let guiClient: GuiClient
  
  @State var showSubView = true
  
  var body: some View {
    Divider().background(Color(.yellow))
    HStack(spacing: 20) {
      
      HStack(spacing: 0) {
        Image(systemName: showSubView ? "chevron.down" : "chevron.right")
          .help("          Tap to toggle details")
          .onTapGesture(perform: { showSubView.toggle() })
        Text(" Gui   ").foregroundColor(.yellow)
          .font(.title)
          .help("          Tap to toggle details")
          .onTapGesture(perform: { showSubView.toggle() })
        
        Text("\(guiClient.station)").foregroundColor(.yellow)
      }
      
      HStack(spacing: 5) {
        Text("Program")
        Text("\(guiClient.program)").foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Handle")
        Text(guiClient.handle.hex).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("ClientId")
        Text(guiClient.clientId ?? "Unknown").foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("LocalPtt")
        Text(guiClient.isLocalPtt ? "Y" : "N").foregroundColor(guiClient.isLocalPtt ? .green : .red)
      }
    }
    if showSubView { GuiClientDetailView(handle: guiClient.handle) }
  }
}

struct GuiClientDetailView: View {
  let handle: UInt32

  @Environment(SettingsModel.self) var settingsModel
  
  var body: some View {
    
    switch settingsModel.objectFilter {
      
    case ObjectFilter.core:
      PanadapterSubView(handle: handle, showMeters: true)
      
    case ObjectFilter.coreNoMeters:
      PanadapterSubView(handle: handle, showMeters: false)
      
    case ObjectFilter.amplifiers:        AmplifierSubView()
    case ObjectFilter.bandSettings:      BandSettingSubView()
    case ObjectFilter.cwx:               CwxSubView()
    case ObjectFilter.equalizers:        EqualizerSubView()
    case ObjectFilter.interlock:         InterlockSubView()
    case ObjectFilter.memories:          MemorySubView()
    case ObjectFilter.meters:            MeterSubView(sliceId: nil, sliceClientHandle: nil, handle: handle)
    case ObjectFilter.misc:              MiscSubView()
    case ObjectFilter.network:           NetworkSubView()
    case ObjectFilter.profiles:          ProfileSubView()
    case ObjectFilter.streams:           StreamSubView(handle: handle)
    case ObjectFilter.usbCable:          UsbCableSubView()
    case ObjectFilter.wan:               WanSubView()
    case ObjectFilter.waveforms:         WaveformSubView()
    case ObjectFilter.xvtrs:             XvtrSubView()
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  GuiClientSubView(store: Store(initialState: ObjectsFeature.State(connectionState: .disconnected)) {
    ObjectsFeature()
  })
  .environment(Listener.shared)
}
