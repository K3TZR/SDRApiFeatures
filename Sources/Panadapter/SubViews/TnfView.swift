//
//  TnfView.swift
//
//
//  Created by Douglas Adams on 5/17/23.
//

import SwiftUI

import FlexApi
import SettingsModel
import SharedModel

struct TnfView: View {
  var panadapter: Panadapter
  var tnf: Tnf
  var radio: Radio
  let size: CGSize
  
  @Environment(ApiModel.self) private var apiModel
  @Environment(SettingsModel.self) private var settings
  
  static let minWidth: CGFloat = 1000
  
  @State var startFrequency: CGFloat?
  @State var cursorInTnf = false
  
  @MainActor var panadapterLowFrequency: CGFloat { CGFloat(panadapter.center - panadapter.bandwidth/2) }
  @MainActor var panadapterHighFrequency: CGFloat { CGFloat(panadapter.center + panadapter.bandwidth/2) }
  @MainActor var tnfFrequency: CGFloat { CGFloat(tnf.frequency) }
  @MainActor var pixelPerHz: CGFloat { size.width / (panadapterHighFrequency - panadapterLowFrequency) }
  
  @MainActor var depthColor: Color {
    if radio.tnfsEnabled {
      switch tnf.depth {
      case Tnf.Depth.normal.rawValue:     settings.tnfNormal
      case Tnf.Depth.deep.rawValue:       settings.tnfDeep
      case Tnf.Depth.veryDeep.rawValue:   settings.tnfVeryDeep
      default:                            settings.tnfInactive
      }
    } else {
      settings.tnfInactive
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      
      Rectangle()
        .fill(tnf.permanent ? settings.tnfPermanent : settings.tnfDeep)
        .border(cursorInTnf ? .red : depthColor)
        .frame(width: max(CGFloat(tnf.width), TnfView.minWidth) * pixelPerHz, height: 0.1 * size.height)
        .offset(x: (tnfFrequency - panadapterLowFrequency) * pixelPerHz )
      
        .onHover { isInsideView in
          cursorInTnf = isInsideView
        }
      
      Rectangle()
        .fill(depthColor)
        .border(cursorInTnf ? .red : depthColor)
        .frame(width: max(CGFloat(tnf.width), TnfView.minWidth) * pixelPerHz, height: 0.9 * size.height)
        .offset(x: (tnfFrequency - panadapterLowFrequency) * pixelPerHz )
      
        .onHover { isInsideView in
          cursorInTnf = isInsideView
        }
    }
    
    // left-drag Tnf frequency
    .gesture(
      DragGesture(minimumDistance: pixelPerHz)
        .onChanged {
          if let startFrequency {
            if abs($0.translation.width) > pixelPerHz {
              let newFrequency = Int(startFrequency + ($0.translation.width/pixelPerHz))
              tnf.setProperty(.frequency, newFrequency.hzToMhz)
            }
          } else {
            startFrequency = CGFloat(tnf.frequency)
          }
        }
        .onEnded { value in
          startFrequency = nil
        }
    )
    
    .contextMenu {
      Button("Delete Tnf") { tnf.remove() }
      Divider()
      Text("Freq: \(tnf.frequency.hzToMhz)")
      Text(" width: \(tnf.width)")
      Button(action: { tnf.setProperty(.permanent, (!tnf.permanent).as1or0) } ) {
        tnf.permanent ? Text("\(Image(systemName: "checkmark")) Permanent") : Text("Permanent")
      }
      Button(action: { tnf.setProperty(.depth, String(Tnf.Depth.normal.rawValue)) } ) {
        tnf.depth == Tnf.Depth.normal.rawValue ? Text("\(Image(systemName: "checkmark")) Normal") : Text("Normal")
      }
      
      Button(action: { tnf.setProperty(.depth, String(Tnf.Depth.deep.rawValue)) }) {
        tnf.depth == Tnf.Depth.deep.rawValue ? Text("\(Image(systemName: "checkmark")) Deep") : Text("Deep")
      }
      
      Button(action: { tnf.setProperty(.depth, String(Tnf.Depth.veryDeep.rawValue)) } ) {
        tnf.depth == Tnf.Depth.veryDeep.rawValue ? Text("\(Image(systemName: "checkmark")) Very Deep") : Text("Very Deep")
      }
      Divider()
      if radio.tnfsEnabled {
        Button("Disable Tnfs")  { apiModel.radio?.setProperty(.tnfsEnabled , "0") }
      } else {
        Button("Enable Tnfs")  { apiModel.radio?.setProperty(.tnfsEnabled , "1")  }
      }
    }
  }
}

#Preview {
  TnfView(panadapter: Panadapter(0x49999999),
          tnf: Tnf(1),
          radio: Radio(Packet()),
          size: CGSize(width: 800, height: 800)
  )
}
