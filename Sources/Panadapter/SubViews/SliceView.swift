//
//  SliceView.swift
//
//
//  Created by Douglas Adams on 5/17/23.
//

import AppKit
import SwiftUI

import Flag
import FlexApi
import SettingsModel
import SharedModel

struct SliceView: View {
  var panadapter: Panadapter
  var slice: Slice
  let isSliceFlag: Bool
  let width: CGFloat
    
  @Environment(SettingsModel.self) private var settings

  @State var startFrequency: CGFloat?
  @State var cursorInSlice = false
  @State var smallFlag = false
  
  @MainActor var panadapterLowFrequency: CGFloat { CGFloat(panadapter.center - panadapter.bandwidth/2) }
  @MainActor var panadapterHighFrequency: CGFloat { CGFloat(panadapter.center + panadapter.bandwidth/2) }
  @MainActor var panadapterCenter: CGFloat { CGFloat(panadapter.center) }
  @MainActor var sliceFrequency: CGFloat { CGFloat(slice.frequency) }
  @MainActor var sliceFilterLow: CGFloat { CGFloat(slice.filterLow) }
  @MainActor var pixelPerHz: CGFloat { width / (panadapterHighFrequency - panadapterLowFrequency) }
  @MainActor var sliceWidth: CGFloat { CGFloat(abs(slice.filterHigh - slice.filterLow)) }
  @MainActor var slicePixelWidth: CGFloat { sliceWidth * pixelPerHz }
  
  @MainActor var sliceOffset: CGFloat { (sliceFrequency - panadapterLowFrequency) * pixelPerHz }
  @MainActor var flagAdjust: CGFloat { sliceFilterLow < 0 ? slicePixelWidth : 0}
  @MainActor var flagWidth: CGFloat { smallFlag ? 150 + flagAdjust : 275  + flagAdjust }
  @MainActor var flagOffset: CGFloat { sliceOffset <= flagWidth ? sliceOffset : sliceOffset - flagWidth }
  
  
  var body: some View {
    //    let _ = Self._printChanges()
    
    ZStack(alignment: .topLeading) {
      
      // flag
      FlagView(slice: slice, isSliceFlag: isSliceFlag, smallFlag: $smallFlag)
      .offset(x: flagOffset)
      
      // frequency line
      Rectangle()
        .frame(width: 2)
        .foregroundColor(slice.active ? settings.sliceActive : settings.sliceInactive)
        .offset(x: (sliceFrequency - panadapterLowFrequency) * pixelPerHz)
      
      // filter outline
      Rectangle()
        .fill(settings.sliceFilter)
//        .border(cursorInSlice ? .red : sliceFilterColor)
        .frame(width: slicePixelWidth)
        .contentShape(Rectangle())
        .offset(x: (sliceFrequency + sliceFilterLow - panadapterLowFrequency) * pixelPerHz)
      
        .onTapGesture(count: 2) {
          slice.setProperty(.active, true.as1or0)
        }
      
        .onHover {
          cursorInSlice = $0
        }
      
      // left-drag Slice frequency
        .gesture(
          DragGesture(minimumDistance: pixelPerHz)
            .onChanged { 
              if let startFrequency {
                let frequencyDelta: CGFloat = $0.translation.width/pixelPerHz
                let newFrequency = Int(startFrequency + frequencyDelta)
                let roundedFrequency = newFrequency - (newFrequency % slice.step)
                slice.setProperty(.frequency, roundedFrequency.hzToMhz)

              } else {
                startFrequency = CGFloat(slice.frequency)
              }
            }
          
            .onEnded { value in
              startFrequency = nil
            }
        )
      
        .contextMenu {
          Button("Delete Slice") { slice.remove() }
          Divider()
          Text("Freq: \(slice.frequency.hzToMhz)")
          Text(" width: \(Int(sliceWidth))")
        }
    }
  }
}
  
#Preview {
  SliceView(panadapter: Panadapter(0x49999999),
            slice: Slice(1),
            isSliceFlag: true,
            width: 800)
}
