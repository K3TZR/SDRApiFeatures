//
//  AtuSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct AtuSubView: View {
  
  @Environment(ApiModel.self) var apiModel
  
  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10) {
      GridRow {
        if apiModel.atuPresent {
          Group {
            Text("ATU")
            HStack(spacing: 5) {
              Text("Enabled")
              Text(apiModel.atu.enabled ? "Y" : "N").foregroundColor(apiModel.atu.enabled ? .green : .red)
            }
            HStack(spacing: 5) {
              Text("Mem enabled")
              Text(apiModel.atu.memoriesEnabled ? "Y" : "N").foregroundColor(apiModel.atu.memoriesEnabled ? .green : .red)
            }          
            HStack(spacing: 5) {
              Text("Using Mem")
              Text(apiModel.atu.usingMemory ? "Y" : "N").foregroundColor(apiModel.atu.usingMemory ? .green : .red)
            }
          }
          .frame(width: 100, alignment: .leading)
          HStack(spacing: 5) {
            Text("Status")
            Text(apiModel.atu.status.rawValue).foregroundColor(.green)
          }
        } else {
          Group {
            Text("ATU")
            Text("Not installed").foregroundColor(.red)
          }
          .frame(width: 100, alignment: .leading)
        }
      }
    }
    .padding(.leading, 20)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  AtuSubView()
    .environment(ApiModel.shared)
}
