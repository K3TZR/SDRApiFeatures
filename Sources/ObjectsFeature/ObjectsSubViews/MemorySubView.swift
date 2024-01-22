//
//  MemorySubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 1/23/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct MemorySubView: View {
  
  @Environment(ApiModel.self) private var apiModel

  var body: some View {
    
    Grid(alignment: .leading, horizontalSpacing: 10) {
      if apiModel.memories.count == 0 {
        GridRow {
          Text("MEMORYs")
          Text("None present").foregroundColor(.red)
        }.frame(width: 100, alignment: .leading)
        
      } else {
        ForEach(apiModel.memories) { memory in
          Group {
            Row1View(memory: memory)
            Row2View(memory: memory)
            GridRow {
              Text("")
            }
          }.frame(width: 100, alignment: .leading)
        }
      }
    }
    .padding(.leading, 20)
  }
}

private struct Row1View: View {
  var memory: Memory
  
  var body: some View {
    
    GridRow {
      HStack(spacing: 5) {
        Text("MEMORY")
        Text("\(memory.id)").foregroundColor(.green)
      }
      Text("\(memory.frequency)").foregroundColor(.green)
      HStack(spacing: 5) {
        Text("Name")
        Text(memory.name).foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Group")
        Text(memory.group.isEmpty ? "none" : memory.group).foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Owner")
        Text(memory.owner).foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Mode")
        Text(memory.mode).foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Step")
        Text("\(memory.step)").foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Power")
        Text("\(memory.rfPower)").foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("Low")
        Text("\(memory.filterLow)").foregroundColor(.green)
      }
      HStack(spacing: 5) {
        Text("High")
        Text("\(memory.filterHigh)").foregroundColor(.green)
      }
    }
  }
}

private struct Row2View: View {
  var memory: Memory
  
  var body: some View {
    GridRow {
      Group {
        HStack(spacing: 5) {
          Text("")
          Text("")
        }
        HStack(spacing: 5) {
          Text("Squelch")
          Text(memory.squelchEnabled ? "Y" : "N").foregroundColor(memory.squelchEnabled ? .green : .red)
        }
        HStack(spacing: 5) {
          Text("Sq Level")
          Text("\(memory.squelchLevel)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Rep")
          Text(memory.offsetDirection).foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Rep Off")
          Text("\(memory.offset)").foregroundColor(.green)
        }
      }
      Group {
        HStack(spacing: 5) {
          Text("Tone")
          Text(memory.toneMode).foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("T Value")
          Text("\(String(format: "%3.0f", memory.toneValue))").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Mark")
          Text("\(memory.rttyMark)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("Shift")
          Text("\(memory.rttyShift)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("DIGL")
          Text("\(memory.digitalLowerOffset)").foregroundColor(.green)
        }
        HStack(spacing: 5) {
          Text("DIGU")
          Text("\(memory.digitalUpperOffset)").foregroundColor(.green)
        }
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  MemorySubView()
    .environment(ApiModel.shared)
}
