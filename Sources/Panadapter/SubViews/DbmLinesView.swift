//
//  DbmLinesView.swift
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

struct DbmLinesView: View {
  var panadapter: Panadapter
  let size: CGSize
  let frequencyLegendHeight: CGFloat
  
  @Environment(SettingsModel.self) private var settings

  @MainActor var pixelPerDbm: CGFloat { (size.height  - frequencyLegendHeight) / (panadapter.maxDbm - panadapter.minDbm) }
  @MainActor var yOffset: CGFloat { panadapter.maxDbm.truncatingRemainder(dividingBy: CGFloat(settings.dbSpacing)) }

  var body: some View {
    Path { path in
      var yPosition: CGFloat = yOffset * pixelPerDbm
      repeat {
        path.move(to: CGPoint(x: 0, y: yPosition))
        path.addLine(to: CGPoint(x: size.width, y: yPosition))
        yPosition += (pixelPerDbm * CGFloat(settings.dbSpacing))
      } while yPosition < size.height - frequencyLegendHeight
    }
    .stroke(settings.dbLines, lineWidth: 1)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  
//  @MainActor var pan: Panadapter {
//    let p = Panadapter(0x49999999)
//    p.center = 14_100_000
//    p.bandwidth = 200_000
//    p.maxDbm = 10
//    p.minDbm = -120
//    return p
//  }
  
  return DbmLinesView(panadapter: Panadapter(0x49999999), size: CGSize(width: 900, height: 450), frequencyLegendHeight: 20)
    .frame(width: 900, height: 450)
}
