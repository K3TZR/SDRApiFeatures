//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 6/25/23.
//

import SwiftUI

import FlexApi

struct ModeView: View {
  var slice: Slice
  
  var body: some View {
    
    let width: CGFloat = 45
    
    Grid(horizontalSpacing: 5) {
      GridRow {
        Picker("", selection: Binding(
          get: { slice.mode},
          set: { slice.setProperty(.mode, $0) } )) {
            ForEach(Slice.Mode.allCases, id: \.self) {
              Text($0.rawValue).tag($0.rawValue)
            }
          }
          .gridCellColumns(2)
          .frame(width: 80)
        Button(action: {  }) {Text("USB")}  // FIXME:
        Button(action: {  }) {Text("LSB")}
        Button(action: {  }) {Text("CW")}
      }.frame(width: width)
      
      GridRow {
        Button(action: {  }) {Text("1.0k")}
        Button(action: {  }) {Text("1.2k")}
        Button(action: {  }) {Text("1.4k")}
        Button(action: {  }) {Text("1.6k")}
        Button(action: {  }) {Text("1.8k")}
      }.frame(width: width)
      
      GridRow {
        Button(action: {  }) {Text("2.0k")}
        Button(action: {  }) {Text("2.2k")}
        Button(action: {  }) {Text("2.4k")}
        Button(action: {  }) {Text("2.6k")}
        Button(action: {  }) {Text("2.8k")}
      }.frame(width: width)
    }
  }
}
