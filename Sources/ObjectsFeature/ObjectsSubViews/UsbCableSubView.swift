//
//  UsbCableSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 8/10/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct UsbCableSubView: View {

  @Environment(ApiModel.self) private var apiModel

  let post = String(repeating: " ", count: 1)
  
  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10) {
      Group {
        if apiModel.usbCables.count == 0 {
          GridRow {
            Group {
              Text("USBCABLEs")
              Text("None present").foregroundColor(.red)
            }.frame(width: 100, alignment: .leading)
          }
          
        } else {
          ForEach(apiModel.usbCables) { cable in
            Group {
              Row1View(cable: cable)
              Row2View(cable: cable)
            }.frame(width: 100, alignment: .leading)
          }
        }
      }
    }.padding(.leading, 20)
  }
}

private struct Row1View: View {
  var cable: UsbCable
  
  var body: some View {
    
    GridRow {
      HStack(spacing: 5) {
        Text("USBCABLE")
        Text(cable.id).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Id")
        Text(cable.id ).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Name")
        Text(cable.name).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Source")
        Text(cable.source).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Enabled")
        Text(cable.enable ? "Y" : "N").foregroundColor(cable.enable ? .green : .red)
      }
      
      HStack(spacing: 5) {
        Text("Band")
        Text(cable.band).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Polarity")
        Text(cable.polarity).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Flow_Control")
        Text(cable.flowControl).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Data_Bits")
        Text(String(format: "%2d", cable.dataBits)).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Stop_Bits")
        Text(String(format: "%2d", cable.stopBits)).foregroundColor(.secondary)
      }
    }
  }
}

private struct Row2View: View {
  var cable: UsbCable
  
  var body: some View {
    
    GridRow {
      HStack(spacing: 5) {
        Text("Parity")
        Text(cable.parity).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Speed")
        Text("\(cable.speed)").foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Source_Rx_Ant")
        Text(cable.sourceRxAnt).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Source_Tx_Ant")
        Text(cable.sourceTxAnt).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Source_Slice")
        Text(String(format: "%2d", cable.sourceSlice)).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Preamp")
        Text(cable.preamp).foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("UsbLog")
        Text(cable.usbLog ? "Y" : "N").foregroundColor(cable.usbLog ? .green : .red)
      }
      
      HStack(spacing: 5) {
        Text("Auto_Report")
        Text(cable.autoReport ? "Y" : "N").foregroundColor(cable.autoReport ? .green : .red)
      }
    }
  }
}


// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  UsbCableSubView()
    .environment(ApiModel.shared)
}
