//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 6/25/23.
//

import SwiftUI

import FlexApi

struct DaxView: View {
  var slice: Slice
  
  var body: some View {
    VStack {
      Picker("DAX Channel", selection: Binding(
        get: { slice.daxChannel },
        set: { slice.setProperty(.daxChannel, String($0)) } )) {
          ForEach(Radio.kDaxChannels, id: \.self) {
            Text("\($0 == 0 ? "None" : String($0))").tag($0)
          }
        }.frame(width: 200)
    }
  }
}
