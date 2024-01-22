//
//  MiscSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 10/20/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature


// ----------------------------------------------------------------------------
// MARK: - View

struct MiscSubView: View {

  @Environment(ApiModel.self) private var apiModel

  func stringArrayToString( _ list: [String]) -> String {
    let str = list.reduce("") {$0 + $1 + ", "}
    return String(str.dropLast(2))
  }
  
  func uint32ArrayToString( _ list: [UInt32]) -> String {
    let str = list.reduce("") {String($0) + String($1) + ", "}
    return String(str.dropLast(2))
  }
  
  var body: some View {
    if let radio = apiModel.radio {
      HStack {
        VStack(alignment: .leading) {
          Text("Software Version")
          Text("Hardware Version")
          Text("Antenna List")
          Text("Microphone List")
          Text("Radio Uptime")
        }.frame(width: 150)
        
        VStack(alignment: .leading) {
          Text(radio.softwareVersion)
          Text(radio.hardwareVersion ?? "Unknown")
          Text(stringArrayToString(radio.antList))
          Text(stringArrayToString(radio.micList))
          Text("\(radio.uptime) (value at time of this connection)")
        }
      }
      .padding(.leading, 40)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  MiscSubView()
    .environment(ApiModel.shared)
}
