//
//  DaxView.swift
//  ViewFeatures/DaxFeature
//
//  Created by Douglas Adams on 12/21/22.
//

import SwiftUI

import FlexApi

public struct DaxView: View {
  var panadapter: Panadapter
  
  public init(panadapter: Panadapter) {
    self.panadapter = panadapter
  }
  
  public var body: some View {

    VStack(alignment: .leading) {
      HStack(spacing: 5) {
        Text("Dax IQ Channel")
        Picker("", selection: Binding(
          get: { panadapter.daxIqChannel },
          set: { panadapter.setProperty(.daxIqChannel, String($0)) })) {
            ForEach(panadapter.daxIqChoices, id: \.self) {
              Text(String($0)).tag($0)
            }
          }
          .labelsHidden()
          .pickerStyle(.menu)
          .frame(width: 50, alignment: .leading)
      }
    }
    .frame(width: 160)
    .padding(5)
  }
}

#Preview {
  DaxView(panadapter: Panadapter(0x49999999))
    .frame(width: 160)
    .padding(5)
}
