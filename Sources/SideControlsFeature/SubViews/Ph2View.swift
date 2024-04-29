//
//  Ph2View.swift
//  ViewFeatures/Ph2Feature
//
//  Created by Douglas Adams on 11/15/22.
//

import SwiftUI

import ApiIntView
import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

public struct Ph2View: View {
  
  public init() {}
  
  @Environment(ApiModel.self) private var apiModel
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        ButtonsView(transmit: apiModel.transmit)
        SlidersView(transmit: apiModel.transmit)
      }
      TxFilterView(transmit: apiModel.transmit)
      MicButtonsView(transmit: apiModel.transmit)
      Divider().background(.blue)
    }
  }
}

private struct ButtonsView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    VStack(alignment: .leading, spacing: 10) {
      Group {
        Text("AM Carrier")
        Toggle(isOn: Binding(
          get: { transmit.voxEnabled},
          set: { transmit.setProperty(.voxEnabled, $0.as1or0) } )) { Text("VOX").frame(width: 55) }
        Text("Vox Delay")
        Toggle(isOn: Binding(
          get: { transmit.companderEnabled},
          set: { transmit.setProperty(.companderEnabled, $0.as1or0) } )) { Text("DEXP").frame(width: 55) }
      }.toggleStyle(.button)
    }
  }
}

private struct SlidersView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    VStack(spacing: 8) {
      HStack(spacing: 20) {
        Text("\(transmit.carrierLevel)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.carrierLevel) }, set: { transmit.setProperty(.amCarrierLevel, String(Int($0))) }), in: 0...100, step: 1)
      }
      HStack(spacing: 20) {
        Text("\(transmit.voxLevel)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.voxLevel) }, set: { transmit.setProperty(.voxLevel, String(Int($0))) }), in: 0...100, step: 1)
      }
      HStack(spacing: 20) {
        Text("\(transmit.voxDelay)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.voxDelay) }, set: { transmit.setProperty(.voxDelay, String(Int($0))) }), in: 0...100, step: 1)
      }
      HStack(spacing: 20) {
        Text("\(transmit.companderLevel)").frame(width: 25, alignment: .trailing)
        Slider(value: Binding(get: { Double(transmit.companderLevel) }, set: { transmit.setProperty(.companderLevel, String(Int($0))) }), in: 0...100, step: 1)
      }
    }
//    .frame(width: 180)
  }
}

struct TxFilterView: View {
  var transmit: Transmit
  
  public var body: some View {
    
    VStack(alignment: .trailing, spacing: 0) {
      Grid {
        GridRow {
          Text("Tx Filter").frame(width: 90, alignment: .leading)
          HStack(spacing: 2) {
            ApiIntView(value: transmit.txFilterLow, action: { transmit.setProperty(.txFilterLow, $0) }, width: 60 )
            
            Stepper("", value: Binding(
              get: { transmit.txFilterLow },
              set: { transmit.setProperty(.txFilterLow, String($0)) }),
                    in:  0...transmit.txFilterHigh,
                    step: 50)
            .labelsHidden()
          }
          
          HStack(spacing: 2) {
            ApiIntView(value: transmit.txFilterHigh, action: { transmit.setProperty(.txFilterHigh, $0) }, width: 60 )
            
            Stepper("", value: Binding(
              get: { transmit.txFilterHigh },
              set: { transmit.setProperty(.txFilterHigh, String($0)) }),
                    in: 0...10_000,
                    step: 50)
            .labelsHidden()
          }
        }
        GridRow {
          Group {
            Text("")
            Text("Low Cut")
            Text("High Cut")
          }
          .font(.footnote)
        }
      }
    }
  }
}

struct MicButtonsView: View {
  var transmit: Transmit
  
  public var body: some View {
    HStack(spacing: 15) {
      Group {
        Toggle(isOn: Binding(
          get: { transmit.micBiasEnabled},
          set: { transmit.setProperty(.micBiasEnabled, $0.as1or0) } )) { Text("Bias").frame(width: 55) }
        Toggle(isOn: Binding(
          get: { transmit.micBoostEnabled},
          set: { transmit.setProperty(.micBoostEnabled, $0.as1or0) } )) { Text("Boost").frame(width: 55) }
        Toggle(isOn: Binding(
          get: { transmit.meterInRxEnabled},
          set: { transmit.setProperty(.meterInRxEnabled, $0.as1or0) } )) { Text("Meter in Rx").frame(width: 70) }
      }
      .toggleStyle(.button)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview("Ph2")  {
  Ph2View()
    .frame(width: 275)
}
