//
//  TransmitSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct TransmitSubView: View {

  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 0) {
      Group {
        Row1View()
        Row2View()
        Row3View()
      }.frame(width: 100, alignment: .leading)
    }
    .padding(.leading, 20)
  }
}

private struct Row1View: View {

  @Environment(ApiModel.self) var apiModel

  var body: some View {
    
    GridRow {
      Text("TRANSMIT")
      Group {
        HStack(spacing: 5) {
          Text("RF_Power")
          Text("\(apiModel.transmit.rfPower)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Tune_Power")
          Text("\(apiModel.transmit.tunePower)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Frequency")
          Text("\(apiModel.transmit.frequency)").foregroundColor(.secondary)
        }
        HStack(spacing: 5) {
          Text("Mon_Level")
          Text("\(apiModel.transmit.ssbMonitorGain)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Comp_Level")
          Text("\(apiModel.transmit.companderLevel)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Mic")
          Text("\(apiModel.transmit.micSelection)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Mic_Level")
          Text("\(apiModel.transmit.micLevel)").foregroundColor(.green)
        }
      }
    }
  }
}
  
private struct Row2View: View {

  @Environment(ApiModel.self) var apiModel

  var body: some View {
    GridRow {
      Text("")
      HStack(spacing: 5) {
        Text("Proc")
        Text(apiModel.transmit.speechProcessorEnabled ? "Y" : "N")
          .foregroundColor(apiModel.transmit.speechProcessorEnabled ? .green : .red)
      }
      HStack(spacing: 5) {
        Text("Comp")
        Text(apiModel.transmit.companderEnabled ? "Y" : "N")
          .foregroundColor(apiModel.transmit.companderEnabled ? .green : .red)
      }
      HStack(spacing: 5) {
        Text("Mon")
        Text(apiModel.transmit.txMonitorEnabled ? "Y" : "N")
          .foregroundColor(apiModel.transmit.txMonitorEnabled ? .green : .red)
      }
      HStack(spacing: 5) {
        Text("Acc")
        Text(apiModel.transmit.micAccEnabled ? "Y" : "N")
          .foregroundColor(apiModel.transmit.micAccEnabled ? .green : .red)
      }
      HStack(spacing: 5) {
        Text("Dax")
        Text(apiModel.transmit.daxEnabled ? "Y" : "N")
          .foregroundColor(apiModel.transmit.daxEnabled ? .green : .red)
      }
      HStack(spacing: 5) {
        Text("Vox")
        Text(apiModel.transmit.voxEnabled ? "Y" : "N")
          .foregroundColor(apiModel.transmit.voxEnabled ? .green : .red)
      }
      HStack(spacing: 5) {
        Text("Vox_Delay")
        Text("\(apiModel.transmit.voxDelay)").foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Vox_Level")
        Text("\(apiModel.transmit.voxLevel)").foregroundColor(.green)
      }
    }
  }
}
  
private struct Row3View: View {

  @Environment(ApiModel.self) var apiModel

  var body: some View {
    GridRow {
      Text("")
      HStack(spacing: 5) {
        Text("Sidetone")
        Text(apiModel.transmit.cwSidetoneEnabled ? "Y" : "N").foregroundColor(apiModel.transmit.cwSidetoneEnabled ? .green : .red)
      }
      HStack(spacing: 5) {
        Text("Level")
        Text("\(apiModel.transmit.cwMonitorGain)").foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Pan")
        Text("\(apiModel.transmit.cwMonitorPan)").foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Pitch")
        Text("\(apiModel.transmit.cwPitch)").foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Speed")
        Text("\(apiModel.transmit.cwSpeed)").foregroundColor(.green)
      }
    }
  }
}
  
  // ----------------------------------------------------------------------------
  // MARK: - Preview
  
#Preview {
  TransmitSubView()
    .environment(ApiModel.shared)
}
