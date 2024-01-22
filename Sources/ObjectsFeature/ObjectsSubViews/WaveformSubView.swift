//
//  WaveformSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 8/4/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

struct WaveformSubView: View {

  @Environment(ApiModel.self) private var apiModel

  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10) {
      if apiModel.waveform.list.isEmpty {
        GridRow {
          Group {
            Text("WAVEFORMs")
            Text("None present").foregroundColor(.red)
          }.frame(width: 100, alignment: .leading)
        }
        
      } else {
        GridRow {
          Group {
            Text("WAVEFORMS").frame(width: 100, alignment: .leading)
            Text(apiModel.waveform.list)
          }
        }
      }
    }.padding(.leading, 20)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  WaveformSubView()
    .environment(ApiModel.shared)
}
