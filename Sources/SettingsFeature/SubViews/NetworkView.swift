//
//  NetworkView.swift
//  ViewFeatures/SettingsFeature/Network
//
//  Created by Douglas Adams on 5/13/21.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

struct NetworkView: View {
  @Bindable var store: StoreOf<SettingsCore>
  
  @Environment(ObjectModel.self) var objectModel

  var body: some View {

    if objectModel.clientInitialized {
      VStack {
        Spacer()
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 20) {
          CurrentAddressView(radio: objectModel.radio!, objectModel: objectModel)
          Spacer()
          Divider().background(Color(.blue))
          Spacer()
          StaticAddressView(radio: objectModel.radio!)
          Spacer()
        }
      }
    } else {
      VStack {
        Text("Radio must be connected").font(.title).foregroundColor(.red)
        Text("to use Network Settings").font(.title).foregroundColor(.red)
      }
    }
  }
}

private struct CurrentAddressView: View {
  var radio: Radio
  var objectModel: ObjectModel

  init(radio: Radio, objectModel: ObjectModel) {
    self.radio = radio
    self.objectModel = objectModel
  }
  
  private var addressTypes = ["Static", "DHCP"]
  
  var body: some View {
    GridRow {
      Text("Serial number")
      Text(radio.packet.serial).foregroundColor(.secondary)
      Text("MAC Address")
      Text(radio.macAddress).foregroundColor(.secondary)
    }
    
    GridRow {
      Text("IP Address")
      Text(radio.packet.publicIp).foregroundColor(.secondary)
      Text("Mask")
      Text(radio.netmask).foregroundColor(.secondary)
    }
    
    GridRow {
      Text("Address Type")
      
      // FIXME:
//      Picker("", selection: Binding(
//        get: { radio.addressType },
//        set: { radio.setProperty(.addressType, $0) } )) {
//          ForEach(addressTypes, id: \.self) {
//            Text($0)
//          }
//        }
//        .labelsHidden()
//        .pickerStyle(.segmented)
//        .frame(width: 100)
      
      Toggle("Enforce Private IP", isOn: Binding(
        get: { radio.enforcePrivateIpEnabled },
        set: { radio.setProperty(.enforcePrivateIpEnabled, $0.as1or0) } ))
      .gridCellColumns(2)
    }
  }
}

private struct StaticAddressView: View {
  var radio: Radio

  private let width: CGFloat = 140
  
  var body: some View {
    
    Text("Static Address (----- NOT implemented -----)").font(.title3).foregroundColor(.blue)
    GridRow() {
      Button("Apply") { }
        .disabled(radio.staticIp.isEmpty || radio.staticMask.isEmpty || radio.staticGateway.isEmpty)
    }
    GridRow {
      Text("IP Address")
//      ApiStringView(hint: "Static ip", value: radio.staticIp, action: { radio.setProperty(.staticIp, $0) } , width: width)
      
      Text("Mask")
//      ApiStringView(hint: "Static mask", value: radio.staticMask, action: { radio.setProperty(.staticMask, $0) } , width: width)
    }
    GridRow {
      Text("Gateway")
//      ApiStringView(hint: "Static gateway", value: radio.staticGateway, action: { radio.setProperty(.staticGateway, $0) } , width: width)
    }
  }
}

#Preview {
  NetworkView(store: Store(initialState: SettingsCore.State()) {
    SettingsCore()
  })
  .environment(ApiModel.shared)
  
  .frame(width: 600, height: 350)
  .padding()
}
