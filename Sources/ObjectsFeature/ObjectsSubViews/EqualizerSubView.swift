//
//  EqualizerSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 8/8/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct EqualizerSubView: View {

  @Environment(ApiModel.self) private var apiModel

  var body: some View {
    Grid(alignment: .leading, horizontalSpacing: 10) {
      HeadingView()
      ForEach(apiModel.equalizers) { eq in
        DetailView(eq: eq)
      }
    }
    .padding(.leading, 40)
  }
}

private struct HeadingView: View {
  
  var body: some View {
    GridRow {
      Group {
        Text("EQUALIZER")
        Text("Enabled")
        Text("63 Hz")
        Text("125 Hz")
        Text("250 Hz")
        Text("500 Hz")
        Text("1000 Hz")
        Text("2000 Hz")
        Text("4000 Hz")
        Text("8000 Hz")
      }.frame(width: 100, alignment: .leading)
    }
  }
}

private struct DetailView: View {
  var eq: Equalizer
  
  var body: some View {
    
    GridRow {
      Group {
        Text(eq.id).foregroundColor(.green)
        Text(eq.eqEnabled ? "Y" : "N").foregroundColor(eq.eqEnabled ? .green : .red)
        Text(String(format: "%#+2d", eq.hz63))
        Text(String(format: "%#+2d", eq.hz125))
        Text(String(format: "%#+2d", eq.hz250))
        Text(String(format: "%#+2d", eq.hz500))
        Text(String(format: "%#+2d", eq.hz1000))
        Text(String(format: "%#+2d", eq.hz2000))
        Text(String(format: "%#+2d", eq.hz4000))
        Text(String(format: "%#+2d", eq.hz8000))
      }
      .frame(width: 50, alignment: .center)
      .foregroundColor(.green)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  EqualizerSubView()
    .environment(ApiModel.shared)
}
