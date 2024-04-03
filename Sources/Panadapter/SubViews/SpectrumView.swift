//
//  SpectrumView.swift
//  
//
//  Created by Douglas Adams on 5/26/23.
//

import SwiftUI

import FlexApi
import SettingsModel
import SharedModel

/*
 // ----------------------------------------------------------------------------
 // MARK: - PanadapterFrame Public properties
 
 public var intensities = [UInt16](repeating: 0, count: kMaxBins) // Array of bin values
 public var binSize = 0                                           // Bin size in bytes
 public var frameNumber = 0                                       // Frame number
 public var segmentStart = 0                                      // first bin in this segment
 public var segmentSize = 0                                       // number of bins in this segment
 public var frameSize = 0                                         // number of bins in the complete frame
 */

struct SpectrumView: View {
  var panadapter: Panadapter
    
  @Environment(SettingsModel.self) private var settings

  var body: some View {
    let spectrumGradient = LinearGradient(gradient: Gradient(stops: [
      .init(color: settings.spectrumGradientColor0, location: settings.spectrumGradientStop0),
      .init(color: settings.spectrumGradientColor1, location: settings.spectrumGradientStop1),
      .init(color: settings.spectrumGradientColor2, location: settings.spectrumGradientStop2),
      .init(color: settings.spectrumGradientColor3, location: settings.spectrumGradientStop3)
    ]), startPoint: .bottom, endPoint: .top)

    ZStack {
      if let frame = panadapter.panadapterFrame {
        switch settings.spectrumType {
        case SpectrumType.gradient.rawValue:
          SpectrumShape(frame: frame, closed: true)
            .fill(spectrumGradient.opacity(settings.spectrumFillLevel / 100))
          SpectrumShape(frame: frame)
            .stroke(settings.spectrumLine)

        case SpectrumType.filled.rawValue:
          ZStack {
            SpectrumShape(frame: frame, closed: true)
              .fill(settings.spectrumFill.opacity(settings.spectrumFillLevel / 100))
            SpectrumShape(frame: frame)
              .stroke(settings.spectrumLine)
          }

        default:
          SpectrumShape(frame: frame)
            .stroke(settings.spectrumLine)
        }
      }
    }
  }
}

struct SpectrumShape: Shape {
  let frame: PanadapterFrame

  var closed = false
  
  func path(in rect: CGRect) -> Path {
    
    return Path { p in
      var x: CGFloat = rect.minX
      var y: CGFloat = CGFloat(frame.intensities[0])
      p.move(to: CGPoint(x: x, y: y))

      for i in 1..<frame.frameSize {
        y = CGFloat(frame.intensities[i])
        x += rect.width / CGFloat(frame.frameSize - 1)
        p.addLine(to: CGPoint(x: x, y: y ))
      }
      if closed {
          p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
          p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
          p.closeSubpath()
      }
    }
  }
}

//#Preview {
//  SpectrumView()
//}
