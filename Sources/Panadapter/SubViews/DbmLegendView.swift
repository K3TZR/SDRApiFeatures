//
//  DbmLegendView.swift
//  TestGridPath
//
//  Created by Douglas Adams on 3/22/23.
//

import SwiftUI

import FlexApi
import SettingsModel
import SharedModel

// ----------------------------------------------------------------------------
// MARK: - View

struct DbmLegendView: View {
  var panadapter: Panadapter
  let size: CGSize
  let frequencyLegendHeight: CGFloat

  @Environment(SettingsModel.self) private var settings

  @State var startDbm: CGFloat?
  
  @MainActor var offset: CGFloat { panadapter.maxDbm.truncatingRemainder(dividingBy: CGFloat(settings.dbSpacing)) }
  
  @MainActor private func pixelPerDbm(_ height: CGFloat) -> CGFloat {
    (height - frequencyLegendHeight) / (panadapter.maxDbm - panadapter.minDbm)
  }
  
  @MainActor var legends: [CGFloat] {
    var array = [CGFloat]()
    
    var currentDbm = panadapter.maxDbm
    repeat {
      array.append( currentDbm )
      currentDbm -= CGFloat(settings.dbSpacing)
    } while ( currentDbm >= panadapter.minDbm )
    return array
  }
  
  var body: some View {
    ZStack(alignment: .trailing) {
      ForEach(Array(legends.enumerated()), id: \.offset) { i, value in
        if value > panadapter.minDbm {
          Text(String(format: "%0.0f", value - offset))
            .position(x: size.width - 20, y: (offset + CGFloat(i) * CGFloat(settings.dbSpacing)) * pixelPerDbm(size.height))
            .foregroundColor(settings.dbLegend)
        }
      }
      
      Rectangle()
        .frame(width: 40)
        .foregroundColor(.white).opacity(0.1)
        .gesture(
          DragGesture()
            .onChanged {
              let isUpper = $0.startLocation.y < size.height/2
              if let startDbm {
                let intNewDbm = Int(startDbm + ($0.translation.height / pixelPerDbm(size.height)))
                if intNewDbm != Int(isUpper ? panadapter.maxDbm : panadapter.minDbm) {
                  panadapter.setProperty(isUpper ? .maxDbm : .minDbm, String(intNewDbm))
                }
              } else {
                startDbm = isUpper ? panadapter.maxDbm : panadapter.minDbm
              }
            }
            .onEnded { _ in
              startDbm = nil
            }
        )
    }
    .contextMenu {
      Button("5 dbm") { settings.dbSpacing = 5 }
      Button("10 dbm") { settings.dbSpacing = 10 }
      Button("15 dbm") { settings.dbSpacing = 15 }
      Button("20 dbm") { settings.dbSpacing = 20 }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  DbmLegendView(panadapter: Panadapter(0x49999999), size: CGSize(width: 900, height: 450), frequencyLegendHeight: 20)
  .frame(width:900, height: 450)
}
