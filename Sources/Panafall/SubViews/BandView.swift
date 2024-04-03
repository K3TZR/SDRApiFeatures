//
//  BandView.swift
//  ViewFeatures/BandFeature
//
//  Created by Douglas Adams on 12/20/22.
//

import SwiftUI

import FlexApi
import SharedModel

public struct BandView: View {
  var panadapter: Panadapter
  
  public init(panadapter: Panadapter) {
    self.panadapter = panadapter
  }
  
  // FIXME: SHould be read from a file
  let bands = [Band("160", "160"), Band("80", "80"), Band("60", "60"),
               Band("40", "40"), Band("30", "30"), Band("20", "20"),
               Band("17", "17"), Band("15", "15"), Band("12", "12"),
               Band("10", "10"), Band("6", "6"), Band("4", "4"),
               Band(""), Band("WWV", "33"), Band("GEN", "34"),
               Band("2200", "2200"), Band("6300", "6300"), Band("XVTR"),
  ]
  
  let columns = [
    GridItem(.fixed(45)),
    GridItem(.fixed(45)),
    GridItem(.fixed(45)),
  ]
  
  public var body: some View {
    
    LazyVGrid(columns: columns, spacing: 5) {
      ForEach(bands, id: \.id) { band in
        Toggle(isOn: Binding(
          get: { panadapter.band == band.label && !band.number.isEmpty },
          set: {_ in if !band.number.isEmpty { panadapter.setProperty(.band, band.number) }} ))
        { Text(band.label).frame(width: 35) }
          .toggleStyle(.button)
          .disabled(band.number.isEmpty)
      }
    }
    .frame(width: 160)
    .padding(.vertical, 5)
  }
}

#Preview("BandView") {
  BandView(panadapter: Panadapter("0x99999999".streamId!))
}
