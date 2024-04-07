//
//  SpectrumView.swift
//  
//
//  Created by Douglas Adams on 5/26/23.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import SharedFeature

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
    
  @Shared(.appStorage("spectrumGradientColor0")) var spectrumGradientColor0: Color = .white.opacity(0.4)
  @Shared(.appStorage("spectrumGradientColor1")) var spectrumGradientColor1: Color = .green
  @Shared(.appStorage("spectrumGradientColor2")) var spectrumGradientColor2: Color = .yellow
  @Shared(.appStorage("spectrumGradientColor3")) var spectrumGradientColor3: Color = .red
  @Shared(.appStorage("spectrumGradientStop0")) var spectrumGradientStop0: Double = 0.2
  @Shared(.appStorage("spectrumGradientStop1")) var spectrumGradientStop1: Double = 0.4
  @Shared(.appStorage("spectrumGradientStop2")) var spectrumGradientStop2: Double = 0.5
  @Shared(.appStorage("spectrumGradientStop3")) var spectrumGradientStop3: Double = 0.6

  @Shared(.appStorage("spectrumFill")) var spectrumFill: Color = .white
  @Shared(.appStorage("spectrumFillLevel")) var spectrumFillLevel: Double = 0
  @Shared(.appStorage("spectrumLine")) var spectrumLine: Color = .white
  @Shared(.appStorage("spectrumType")) var spectrumType: String = SpectrumType.line.rawValue

  var body: some View {
    let spectrumGradient = LinearGradient(gradient: Gradient(stops: [
      .init(color: spectrumGradientColor0, location: spectrumGradientStop0),
      .init(color: spectrumGradientColor1, location: spectrumGradientStop1),
      .init(color: spectrumGradientColor2, location: spectrumGradientStop2),
      .init(color: spectrumGradientColor3, location: spectrumGradientStop3)
    ]), startPoint: .bottom, endPoint: .top)

    ZStack {
      if let frame = panadapter.panadapterFrame {
        switch spectrumType {
        case SpectrumType.gradient.rawValue:
          SpectrumShape(frame: frame, closed: true)
            .fill(spectrumGradient.opacity(spectrumFillLevel / 100))
          SpectrumShape(frame: frame)
            .stroke(spectrumLine)

        case SpectrumType.filled.rawValue:
          ZStack {
            SpectrumShape(frame: frame, closed: true)
              .fill(spectrumFill.opacity(spectrumFillLevel / 100))
            SpectrumShape(frame: frame)
              .stroke(spectrumLine)
          }

        default:
          SpectrumShape(frame: frame)
            .stroke(spectrumLine)
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
