//
//  FrequencyLinesView.swift
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

struct FrequencyLinesView: View {
  var panadapter: Panadapter
  let spacings: [(Int,Int)]
  let leftWidth: CGFloat
  
  @Environment(ApiModel.self) private var apiModel
  @Environment(SettingsModel.self) private var settings

  @State var startCenter: CGFloat?
  @State var rightMouseDownLocation: NSPoint = .zero
  @State var leftMouseDownLocation: NSPoint = .zero
  @State var scrollWheelLocation: NSPoint = .zero

  @MainActor private var spacing: CGFloat {
    for spacing in spacings {
      if panadapter.bandwidth >= spacing.0 { return CGFloat(spacing.1) }
    }
    return CGFloat(spacings[0].1)
  }
  
  @MainActor private func initialXPosition(_ width: CGFloat) -> CGFloat {
    -CGFloat(panadapter.center - panadapter.bandwidth/2).truncatingRemainder(dividingBy: spacing) * pixelPerHz(width)
  }
  
  @MainActor private func pixelPerHz(_ width: CGFloat) -> CGFloat {
    width / CGFloat(panadapter.bandwidth)
  }
  
  @MainActor private func clickFrequency(_ width: CGFloat) -> Int {
    let freq = Int( CGFloat(panadapter.center - panadapter.bandwidth/2) + CGFloat(panadapter.bandwidth) * ((rightMouseDownLocation.x - leftWidth) / width) )
    return freq
  }
  
  @MainActor private var start: CGFloat { CGFloat(panadapter.center) - CGFloat(panadapter.bandwidth)/2 }
  
  var body: some View {
    GeometryReader { g in
      Path { path in
        var xPosition: CGFloat = initialXPosition(g.size.width)
        repeat {
          path.move(to: CGPoint(x: xPosition, y: 0))
          path.addLine(to: CGPoint(x: xPosition, y: g.size.height))
          xPosition += pixelPerHz(g.size.width) * spacing
        } while xPosition < g.size.width
      }
      .stroke(settings.gridLines, lineWidth: 1)
      .contentShape(Rectangle())
      
      .onAppear(perform: {
        // setup right mouse down tracking
//        NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) {
//          rightMouseDownLocation = $0.locationInWindow
//          return $0
//        }
        
        // setup left mouse down tracking
        NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) {
          leftMouseDownLocation = $0.locationInWindow
          return $0
        }
      })

      // Double-Click to move nearest Slice
      .gesture(
        TapGesture(count: 2).onEnded {
          let clickFrequency: Int = Int((leftMouseDownLocation.x / pixelPerHz(g.size.width)) + start)
          apiModel.sliceMove(panadapter, clickFrequency)
        }
      )

      // left-drag Panadapter center frequency
      .gesture(
        DragGesture().onChanged {
            if let startCenter {
              if abs($0.translation.width) > pixelPerHz(g.size.width) {
                let newCenter = Int(startCenter - ($0.translation.width / pixelPerHz(g.size.width) ))
                panadapter.setProperty(.center, newCenter.hzToMhz)
              }
            } else {
              startCenter = CGFloat(panadapter.center)
            }
          }
          .onEnded { value in
            startCenter = nil
          }
      )
      
      .contextMenu {
        Button("Create Slice") { apiModel.requestSlice(on: panadapter, at: clickFrequency(g.size.width)) }
        Button("Create Tnf") { apiModel.requestTnf(at: clickFrequency(g.size.width)) }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
//  var pan: Panadapter {
//    let p = Panadapter(0x49999999)
//    p.center = 14_100_000
//    p.bandwidth = 200_000
//    p.maxDbm = 10
//    p.minDbm = -120
//    return p
//  }
  
  return FrequencyLinesView(panadapter: Panadapter(0x49999999),
                            spacings: [
                              (10_000_000, 1_000_000),
                              (5_000_000, 500_000),
                              (1_000_000, 100_000),
                              (500_000, 50_000),
                              (400_000, 40_000),
                              (300_000, 30_000),
                              (200_000, 20_000),
                              (100_000, 10_000),
                              (50_000, 5_000),
                              (40_000, 4_000),
                              (30_000, 3_000),
                              (20_000, 2_000),
                              (10_000, 1_000)
                            ],
                            leftWidth: 0)
  .frame(width:800, height: 600)
}
