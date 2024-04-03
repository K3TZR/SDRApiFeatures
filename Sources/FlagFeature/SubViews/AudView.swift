//
//  AudView.swift
//  
//
//  Created by Douglas Adams on 6/25/23.
//
import SwiftUI

import FlexApi

struct AudView: View {
  var slice: Slice
  
  var body: some View {
    VStack(alignment: .leading, spacing: 5) {

      Grid (verticalSpacing: 5) {

        GridRow {
          Image(systemName: slice.audioMute ? "speaker.slash": "speaker")
            .frame(width: 40)
            .font(.title2)
            .onTapGesture {
              slice.setProperty(.audioMute, (!slice.audioMute).as1or0)
            }
          Slider(value: Binding(
            get: { Double(slice.audioGain) },
            set: { slice.setProperty(.audioGain, String(Int($0))) } ), in: 0...100)
          .frame(width: 160)
          Text(String(format: "%d",slice.audioGain))
            .frame(width: 40)
            .font(.title3)
            .multilineTextAlignment(.trailing)
        }
        
        GridRow {
          Text("L")
            .font(.title3)
          Slider(value: Binding(
            get: { Double(slice.audioPan) },
            set: { slice.setProperty(.audioPan, String(Int($0))) } ), in: 0...100).frame(width: 160)
          Text("R")
            .font(.title3)
        }
      }

      HStack {
        Picker("", selection: Binding(
          get: { slice.agcMode },
          set: { slice.setProperty(.agcMode, $0) } )) {
            ForEach(Slice.AgcMode.allCases, id: \.self) {
              Text($0.rawValue).tag($0.rawValue)
            }
          }.frame(width: 100)
        Slider(value: Binding(
          get: { Double(slice.agcThreshold) },
          set: { slice.setProperty(.agcThreshold, String(Int($0))) } ), in: 0...100).frame(width: 100)
        Text(String(format: "%d", slice.agcThreshold))
          .frame(width: 40)
          .font(.title3)
          .multilineTextAlignment(.trailing)
      }.padding(.bottom, 5)
    }
    .controlSize(.small)
  }
}
