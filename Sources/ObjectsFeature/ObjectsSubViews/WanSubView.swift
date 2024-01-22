//
//  WanSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 8/10/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct WanSubView: View {

  @Environment(ApiModel.self) private var apiModel

  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10) {
      GridRow {
        Text("WAN").frame(width: 100, alignment: .leading)
        Group {
          HStack(spacing: 5) {
            Text("Radio Authenticated")
            Text(apiModel.wan.radioAuthenticated ? "Y" : "N").foregroundColor(apiModel.wan.radioAuthenticated ? .green : .red)
          }
          HStack(spacing: 5) {
            Text("Server Connected")
            Text(apiModel.wan.serverConnected ? "Y" : "N").foregroundColor(apiModel.wan.serverConnected ? .green : .red)
          }
        }.frame(width: 210, alignment: .leading)
      }
    }
    .padding(.leading, 20)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  WanSubView()
    .environment(ApiModel.shared)
}
