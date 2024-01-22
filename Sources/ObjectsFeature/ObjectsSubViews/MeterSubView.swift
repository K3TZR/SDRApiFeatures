//
//  MeterSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 1/24/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct MeterSubView: View {
  let sliceId: UInt32?
  let sliceClientHandle: UInt32?
  let handle: UInt32
  
  @Environment(ApiModel.self) private var apiModel

  func showMeter(_ id: UInt32?, _ clientHandle: UInt32?, _ source: String, _ group: String) -> Bool {
    if id == nil { return true }
    if clientHandle != handle { return false }
    if source != "slc" { return false }
    if UInt32(group) != id { return false }
    return true
  }
  
  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10) {
      HeadingView(sliceId: sliceId)
      ForEach(apiModel.meters ) { meter in
        if showMeter(sliceId, sliceClientHandle, meter.source, meter.group) {
          DetailView(meter: meter, sliceId: sliceId)
        }
      }
      .foregroundColor(.secondary)
    }
    .padding(.leading, 40)
  }
}

private struct HeadingView: View {
  let sliceId: UInt32?
  
  var body: some View {
    GridRow {
      Group {
        Text("METER #")
        if sliceId == nil {
          Text("Group")
          Text("Source")
        }
      }.frame(width: 60, alignment: .leading)
      
      Text("Name").frame(width: 110)
      Group {
        Text("Value")
        Text("Units")
        Text("Fps")
      }.frame(width: 70)
      Text("Description")
    }
  }
}

private struct DetailView: View {
  var meter: Meter
  let sliceId: UInt32?
  
  func valueColor(_ value: Float, _ low: Float, _ high: Float) -> Color {
    if value > high { return .red }
    if value < low { return .yellow }
    return .green
  }
  
//  @State var interval: TimeInterval = 1.0
//  @State var throttledValue: CGFloat = 0.0      // FIXME: need throttling
  
  var body: some View {
    
    GridRow {
      Group {
        Text(String(format: "% 3d", meter.id))
        if sliceId == nil {
          Text(meter.group)
          Text(meter.source)
        }
      }.frame(width: 60, alignment: .center)
      Text(meter.name).frame(width: 110, alignment: .leading)
      Group {
        Text(String(format: "%-4.2f", meter.value))
          .help("        range: \(String(format: "%-4.2f", meter.low)) to \(String(format: "%-4.2f", meter.high))")
          .foregroundColor(valueColor(meter.value, meter.low, meter.high))
//          .onReceive(meter.$value.throttle(for: RunLoop.SchedulerTimeType.Stride(interval), scheduler: RunLoop.main, latest: true)) { throttledValue = CGFloat($0) }

        Text(meter.units)
        Text(String(format: "% 2d", meter.fps))
      }.frame(width: 70, alignment: .trailing)
      Text(meter.desc).foregroundColor(.primary)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  MeterSubView(sliceId: 1, sliceClientHandle: nil, handle: 1)
    .environment(ApiModel.shared)
}
