//
//  DbmLegendView.swift
//  TestGridPath
//
//  Created by Douglas Adams on 3/22/23.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct DbmLegendView: View {
  var panadapter: Panadapter
  let size: CGSize
  let frequencyLegendHeight: CGFloat

  @Shared(.appStorage("dbLegend")) var dbLegend: Color = .green
  @Shared(.appStorage("dbSpacing")) var dbSpacing: Int = 10

  @State var startDbm: CGFloat?
  
  @MainActor var offset: CGFloat { panadapter.maxDbm.truncatingRemainder(dividingBy: CGFloat(dbSpacing)) }
  
  @MainActor private func pixelPerDbm(_ height: CGFloat) -> CGFloat {
    (height - frequencyLegendHeight) / (panadapter.maxDbm - panadapter.minDbm)
  }
  
  @MainActor var legends: [CGFloat] {
    var array = [CGFloat]()
    
    var currentDbm = panadapter.maxDbm
    repeat {
      array.append( currentDbm )
      currentDbm -= CGFloat(dbSpacing)
    } while ( currentDbm >= panadapter.minDbm )
    return array
  }
  
  var body: some View {
    ZStack(alignment: .trailing) {
      ForEach(Array(legends.enumerated()), id: \.offset) { i, value in
        if value > panadapter.minDbm {
          Text(String(format: "%0.0f", value - offset))
            .position(x: size.width - 20, y: (offset + CGFloat(i) * CGFloat(dbSpacing)) * pixelPerDbm(size.height))
            .foregroundColor(dbLegend)
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
      Button("5 dbm") { dbSpacing = 5 }
      Button("10 dbm") { dbSpacing = 10 }
      Button("15 dbm") { dbSpacing = 15 }
      Button("20 dbm") { dbSpacing = 20 }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  DbmLegendView(panadapter: Panadapter(0x49999999, ApiModel.shared), size: CGSize(width: 900, height: 450), frequencyLegendHeight: 20)
  .frame(width:900, height: 450)
}
