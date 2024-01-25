//
//  TesterSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 1/25/22.
//

import ComposableArchitecture
import SwiftUI

import ListenerFeature
import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct TesterSubView: View {
  
  @Environment(ApiModel.self) private var apiModel
  @Environment(ListenerModel.self) private var listenerModel

  var body: some View {
    if apiModel.radio != nil {
      VStack(alignment: .leading) {
        Divider().background(Color(.green))
        HStack(spacing: 10) {
          
          Text("SDRApi").foregroundColor(.green)
            .font(.title)
          
          HStack(spacing: 5) {
            Text("Bound to Station")
            Text("\(listenerModel.activeStation ?? "none")").foregroundColor(.secondary)
          }
          TesterRadioView()
        }
      }
    }
  }
}

struct TesterRadioView: View {

  @Environment(ApiModel.self) private var apiModel

  var body: some View {
      HStack(spacing: 5) {
        Text("Handle")
        Text(apiModel.connectionHandle?.hex ?? "").foregroundColor(.secondary)
      }
      
      HStack(spacing: 5) {
        Text("Client Id")
        Text("\(apiModel.boundClientId ?? "none")").foregroundColor(.secondary)
      }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  TesterSubView()
    .environment(ApiModel.shared)
    .environment(ListenerModel.shared)
}
