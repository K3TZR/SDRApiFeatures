//
//  LevelIndicatorView.swift
//  ViewFeatures/LevelIndicatorView
//
//  Created by Douglas Adams on 4/29/22.
//

import Foundation
import SwiftUI

import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - Public Structs & Enums

public enum IndicatorType {
  case power
  case swr
  case alc
  case sMeter
  case micLevel
  case compression
  case dax
  case other(IndicatorStyle)
}

public enum LegendPosition {
  case top
  case bottom
  case none
}

public enum TintType {
  case normal
  case warning
  case critical
}

public struct Tick {
  public var value: CGFloat
  public var label: String

  public init
  (
    value: CGFloat,
    label: String = ""
  )
  {
    self.value = value
    self.label = label
  }
}

public struct IndicatorStyle {
  var width: CGFloat
  var height: CGFloat
  var barHeight: CGFloat
  var isFlipped: Bool
  var left: CGFloat
  var right: CGFloat
  var warningLevel: CGFloat
  var criticalLevel: CGFloat
  var backgroundColor: Color
  var normalColor: Color
  var warningColor: Color
  var criticalColor: Color
  var borderColor: Color
  var tickColor: Color
  var legendFont: Font
  var legendColor: Color
  var legendPosition: LegendPosition
  var drawOutline: Bool
  var outlineColor: Color
  var outlineStepped: Bool
  var drawTicks: Bool
  var ticks: [Tick]
  var showPeak: Bool
  
  public init
  (
    width: CGFloat = 220,
    height: CGFloat = 30,
    barHeight: CGFloat = 15,
    isFlipped: Bool = false,
    left: CGFloat = 0.0,
    right: CGFloat = 1.0,
    warningLevel: CGFloat = 0.8,
    criticalLevel: CGFloat = 0.9,
    backgroundColor: Color = .clear,
    normalColor: Color = .blue,
    warningColor: Color = .yellow,
    criticalColor: Color = .red,
    borderColor: Color = .blue,
    tickColor: Color = .blue,
    legendFont: Font = Font.system(size: 12).monospaced(),
    legendColor: Color = .orange,
    legendPosition: LegendPosition = .top,
    drawOutline: Bool = true,
    outlineColor: Color = .blue,
    outlineStepped: Bool = false,
    drawTicks: Bool = true,
    ticks: [Tick] = [],
    showPeak: Bool = true
  )
  {
    self.width = width
    self.height = height
    self.barHeight = barHeight
    self.isFlipped = isFlipped
    self.left = left
    self.right = right
    self.warningLevel = warningLevel
    self.criticalLevel = criticalLevel
    self.backgroundColor = backgroundColor
    self.normalColor = normalColor
    self.warningColor = warningColor
    self.criticalColor = criticalColor
    self.borderColor = borderColor
    self.tickColor = tickColor
    self.legendFont = legendFont
    self.legendColor = legendColor
    self.legendPosition = legendPosition
    self.drawOutline = drawOutline
    self.outlineColor = outlineColor
    self.outlineStepped = outlineStepped
    self.drawTicks = drawTicks
    self.ticks = ticks
    self.showPeak = showPeak
  }
}

// ----------------------------------------------------------------------------
// MARK: - Private Structs & Enums

private let alcStyle = IndicatorStyle(
  left: 0,
  right: 100,
  warningLevel: 0.0,
  criticalLevel: 0.0,
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:20, label: "20"),
      Tick(value:40, label: "40"),
      Tick(value:60, label: "60"),
      Tick(value:80, label: "80"),
      Tick(value:100, label: "100"),
    ]
)

private let compressionStyle = IndicatorStyle(
  left: 0.0,
  right: 25.0,
  warningLevel: 20,
  criticalLevel: 25,
  ticks:
    [
      Tick(value: 0.0, label: "0"),
      Tick(value: 5.0, label: "5"),
      Tick(value: 10.0, label: "10"),
      Tick(value: 15.0, label: "15"),
      Tick(value: 20.0, label: "20"),
      Tick(value: 25.0, label: "25"),
    ]
)

private let daxStyle = IndicatorStyle(
  width: 340,
  left: -40.0,
  right: 10.0,
  warningLevel: 0.0,
  criticalLevel: 0.0,
  ticks:
    [
      Tick(value:-40.00, label: "-40"),
      Tick(value:-30.0, label: "-30"),
      Tick(value:-20.0, label: "-20"),
      Tick(value:-10.0, label: "-10"),
      Tick(value:0.0, label: "0"),
      Tick(value:10.0, label: "10"),
    ]
)

private let micStyle = IndicatorStyle(
  left: -40.0,
  right: 5.0,
  warningLevel: 0.0,
  criticalLevel: 0.0,
  ticks:
    [
      Tick(value:-40.00, label: "-40"),
      Tick(value:-35.0),
      Tick(value:-30.0, label: "-30"),
      Tick(value:-25.0),
      Tick(value:-20.0, label: "-20"),
      Tick(value:-15.0),
      Tick(value:-10.0, label: "-10"),
      Tick(value:-5.0),
      Tick(value:0.0, label: "0"),
      Tick(value:5.0, label: "+5"),
    ]
)

private let powerStyle = IndicatorStyle(
  left: 0.0,
  right: 120,
  warningLevel: 100,
  criticalLevel: 100,
  ticks:
    [
      Tick(value:0.0, label: "0"),
      Tick(value:10.0),
      Tick(value:20.0, label: "20"),
      Tick(value:30.0),
      Tick(value:40.0, label: "40"),
      Tick(value:50),
      Tick(value:60, label: "60"),
      Tick(value:70),
      Tick(value:80, label: "80"),
      Tick(value:90),
      Tick(value:100, label: "100"),
      Tick(value:110),
      Tick(value:120),
    ]
)

private let sMeterStyle = IndicatorStyle(
  height: 20,
  barHeight: 5,
  left: 0,
  right: 13,
  warningLevel: 9.0,
  criticalLevel: 10.0,
  legendFont: Font.system(size: 10).monospaced(),
  legendPosition: .bottom,
  drawOutline: false,
  outlineColor: .green,
  drawTicks: false,
  ticks:
    [
      Tick(value:1.0, label: "1"),
      Tick(value:3.0, label: "3"),
      Tick(value:5.0, label: "5"),
      Tick(value:7.0, label: "7"),
      Tick(value:9.0, label: "9"),
      Tick(value:11.0, label: "+20"),
//      Tick(value:13.0, label: "+40"),
    ],
  showPeak: false
)

private let swrStyle = IndicatorStyle(
  left: 1.0,
  right: 3.0,
  warningLevel: 2.5,
  criticalLevel: 2.5,
  ticks:
    [
      Tick(value:1.0, label: "1"),
      Tick(value:1.25),
      Tick(value:1.5, label: "1.5"),
      Tick(value:1.75),
      Tick(value:2.0, label: "SWR"),
      Tick(value:2.25),
      Tick(value:2.5, label: "2.5"),
      Tick(value:2.75),
      Tick(value:3.0, label: "3"),
    ]
)

// ----------------------------------------------------------------------------
// MARK: - Views

public struct LevelIndicatorView: View {
  var levels: SignalLevel
  var type: IndicatorType
  var style: IndicatorStyle
  
  public init(
    levels: SignalLevel,
    type: IndicatorType
  )
  {
    self.levels = levels
    self.type = type
    
    switch type {
    case .power:             style = powerStyle
    case .swr:               style = swrStyle
    case .alc:               style = alcStyle
    case .sMeter:            style = sMeterStyle
    case .micLevel:          style = micStyle
    case .compression:       style = compressionStyle
    case .dax:               style = daxStyle
    case .other(let style):  self.style = style
    }
  }
  
  var legendWidth: CGFloat {
    if style.ticks.count % 2 == 0 {
      return style.width / CGFloat(style.ticks.count)
    } else {
      return style.width / CGFloat(style.ticks.count )
    }
  }

  var effectiveWidth: CGFloat { style.width - legendWidth}

  public var body: some View {
    
    VStack(alignment: .leading, spacing: 0) {
      // draw top legend (if any)
      if style.legendPosition == .top {
        LegendView(style: style, legendWidth: legendWidth)
      }
      
      ZStack(alignment: .bottomLeading) {
        BarView(levels: levels, style: style, width: effectiveWidth)
        if style.drawOutline { OutlineView(style: style, width: effectiveWidth, legendWidth: legendWidth) }
        if style.drawTicks { TickView(style: style, width: effectiveWidth) }
      }
      .offset(x: legendWidth/2)
      .frame(height: style.barHeight)
      .clipped()
      
      // draw bottom legend (if any)
      if style.legendPosition == .bottom {
        LegendView(style: style, legendWidth: legendWidth)
      }
    }
    .frame(width: style.width, height: style.height, alignment: .leading)
    .rotationEffect(.degrees(style.isFlipped ? 180 : 0))

  }
}

// ---------- LEGEND (above or below) ----------
struct LegendView: View {
  var style: IndicatorStyle
  var legendWidth: CGFloat
  
  var body: some View {
    
    ZStack {
      HStack(spacing: 0) {
        ForEach(style.ticks, id: \.value) { tick in
          Text(tick.label).font(style.legendFont)
            .frame(width: legendWidth, alignment: .center)
          //            .border(.red)
        }
        .foregroundColor(style.legendColor)
      }
    }
  }
}

// ---------- BAR (active and peak) ----------
private struct BarView: View {
  var levels: SignalLevel
  var style: IndicatorStyle
  var width: CGFloat

  func clamped(_ value: CGFloat) -> CGFloat {
    if value > style.right {
      style.right
    } else if value < style.left {
      style.left
    } else {
      value
    }
  }

  var body: some View {
    let normalPerCent = style.isFlipped ? style.right - style.warningLevel : style.warningLevel - style.left
    let warningPerCent = style.isFlipped ? style.warningLevel - style.criticalLevel : style.criticalLevel - style.warningLevel
    let criticalPerCent = style.isFlipped ? style.criticalLevel - style.left : style.right - style.criticalLevel
    let clipPerCent = style.isFlipped ? style.right - clamped(levels.rms) : clamped(levels.rms) - style.left
    let valueRange = style.isFlipped ? style.left - style.right : style.right - style.left
    
    ZStack(alignment: .leading) {
      HStack(spacing: 0) {
        Rectangle()
          .fill(.green)
          .frame(width: (width) * (normalPerCent) / valueRange, alignment: .leading)
        Rectangle()
          .fill(style.warningColor)
          .frame(width: (width) * (warningPerCent) / valueRange, alignment: .leading)
        Rectangle()
          .fill(style.criticalColor)
          .frame(width: (width) * (criticalPerCent) / valueRange, alignment: .leading)
      }
      .padding(.vertical, 2)
      .frame(width: (width) * (clipPerCent) / valueRange, alignment: .leading)
      .clipped()
      
      if style.showPeak {
        Rectangle()
          .fill(levels.peak > style.warningLevel ? style.criticalColor : .white)
          .frame(width: 4, alignment: .leading)
          .offset(x: (width) * (clamped(levels.peak) - (style.isFlipped ? style.right : style.left)) / valueRange)
      }
    }
  }
}

// ---------- TICK MARKS ----------
private struct TickView: View {
  var style: IndicatorStyle
  var width: CGFloat

  func tintColor(_ value: CGFloat) -> Color {
    if value < style.warningLevel {
      style.normalColor
    } else if value < style.criticalLevel {
      style.warningColor
    } else {
      style.criticalColor
    }
  }

  var valueRange: CGFloat { style.right - style.left }

  var body: some View {
    
    var tickLocation: CGFloat = 0
    
    ForEach(style.ticks, id: \.value) { tick in
      Path { path in
        tickLocation = (tick.value - style.left) * ((width) / valueRange)
        path.move(to: CGPoint(x: tickLocation , y: style.height))
        path.addLine(to: CGPoint(x: tickLocation, y: 0))
      }.stroke(tintColor(tick.value))
    }
  }
}

// ---------- OUTLINE (top an/or bottom) ----------
private struct OutlineView: View {
  var style: IndicatorStyle
  var width: CGFloat
  var legendWidth: CGFloat

  func tintColor(_ value: CGFloat) -> Color {
    if value < style.warningLevel {
      style.normalColor
    } else if value < style.criticalLevel {
      style.warningColor
    } else {
      style.criticalColor
    }
  }

  var valueRange: CGFloat { style.right - style.left }
  
  var body: some View {
    
    var tickLocation: CGFloat = 0
    
    ForEach(style.ticks, id: \.value) { tick in
      Path { path in
        //        if style.isFlipped && tick.value != style.left {
        //          tickLocation = ( style.right - tick.value) * ((width) / valueRange)
        //
        if tick.value != style.right {
          tickLocation = (tick.value - style.left) * ((width) / valueRange)
          //        }
          path.move(to: CGPoint(x: tickLocation, y: 0))
          path.addLine(to: CGPoint(x: tickLocation + legendWidth, y: 0))
          
          path.move(to: CGPoint(x: tickLocation, y: style.barHeight))
          path.addLine(to: CGPoint(x: tickLocation + legendWidth, y: style.barHeight))
        }
        
      }.stroke(tintColor(tick.value))
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Previews

let levelsRF = SignalLevel(rms: 101.0, peak: 110.0)

#Preview("RF Power @ \(levelsRF.desc))") {
    LevelIndicatorView(levels: levelsRF, type: .power)
}

let levelsALC = SignalLevel(rms: 25.0, peak: 30.0)
#Preview("ALC Level @ \(levelsALC.desc)") {
  LevelIndicatorView(levels: levelsALC, type: .alc)
}

let levelsMIC = SignalLevel(rms: 1.0, peak: 4.0)
#Preview("Mic Level @ \(levelsMIC.desc)") {
  LevelIndicatorView(levels: levelsMIC, type: .micLevel)
}

let levelsDAX = SignalLevel(rms: -10.0, peak: -4.0)
#Preview("DAX Level @ \(levelsDAX.desc)") {
  LevelIndicatorView(levels: levelsDAX, type: .dax)
}

let levelsSWR = SignalLevel(rms: 2.6, peak: 2.9)
#Preview("SWR Level @ \(levelsSWR.desc)") {
  LevelIndicatorView(levels: levelsSWR, type: .swr)
}

let levelsSMETER = SignalLevel(rms: 3.0, peak: 5.0)
#Preview("SMETER Level @ \(levelsSMETER.desc)") {
  LevelIndicatorView(levels: levelsSMETER, type: .sMeter)
}

let levelsCOMPRESSION = SignalLevel(rms: -0.0, peak: -0.0)
#Preview("Compression Level @ \(levelsCOMPRESSION.desc)") {
  LevelIndicatorView(levels: levelsCOMPRESSION, type: .compression)
}
