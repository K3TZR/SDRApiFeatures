//
//  BandSettingsSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct BandSettingSubView: View {

  @Environment(ApiModel.self) private var apiModel

  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10) {
      if apiModel.bandSettings.count == 0 {
      GridRow {
        Text("BANDSETTINGs")
        Text("None present").foregroundColor(.red)
      }.frame(width: 80, alignment: .center)
      
    } else {
        HeadingView()
        ForEach(apiModel.bandSettings.sorted(by: {$0.name < $1.name})) { setting in
          DetailView(setting: setting)
        }.frame(width: 80, alignment: .center)
      }
    }
    .padding(.leading, 20)
  }
}

private struct HeadingView: View {
  
  var body: some View {
    
    GridRow {
      Group {
        Text("BAND")
        Text("Rf Power")
        Text("Tune Power")
        Text("Tx1")
        Text("Tx2")
        Text("Tx3")
        Text("Acc Tx")
      }.frame(width: 80, alignment: .center)
      Group {
        Text("Acc Tx Req")
        Text("Rca Tx Req")
        Text("HW Alc")
        Text("Inhibit")
      }
    }
  }
}

private struct DetailView: View {
  var setting: BandSetting
  
  var body: some View {
    
    GridRow {
      Group {
        Text(setting.name == 999 ? " GEN" : String(format: "%#4d", setting.name)).foregroundColor(.green)
        Text(String(format: "%#3d", setting.rfPower)).foregroundColor(.green)
        Text(String(format: "%#3d", setting.tunePower)).foregroundColor(.green)
        Text(setting.tx1Enabled ? "Y" : "N").foregroundColor(setting.tx1Enabled  ? .green : .red)
        Text(setting.tx2Enabled ? "Y" : "N").foregroundColor(setting.tx2Enabled  ? .green : .red)
        Text(setting.tx3Enabled ? "Y" : "N").foregroundColor(setting.tx3Enabled  ? .green : .red)
      }.frame(width: 80, alignment: .center)
      Group {
        Text(setting.accTxEnabled ? "Y" : "N").foregroundColor(setting.accTxEnabled  ? .green : .red)
        Text(setting.accTxReqEnabled ? "Y" : "N").foregroundColor(setting.accTxReqEnabled ? .green : .red)
        Text(setting.rcaTxReqEnabled ? "Y" : "N").foregroundColor(setting.rcaTxReqEnabled ? .green : .red)
        Text(setting.hwAlcEnabled ? "Y" : "N").foregroundColor(setting.hwAlcEnabled ? .green : .red)
        Text(setting.inhibit ? "Y" : "N").foregroundColor(setting.inhibit ? .green : .red)
      }.frame(width: 80, alignment: .center)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  BandSettingSubView()
    .environment(ApiModel.shared)
}
