//
//  FlagView.swift
//  FlagFeatures/Flag
//
//  Created by Douglas Adams on 4/3/21.
//

import SwiftUI

import ApiIntView
import LevelIndicatorView
import FlexApi
import FlagAntennaPopover
import SettingsModel
import SharedModel

public enum FlagMode: String {
  case aud
  case dsp
  case mode
  case xrit
  case dax
  case none
}

// ----------------------------------------------------------------------------
// MARK: - Main view

public struct FlagView: View {
  var slice: Slice
  let isSliceFlag: Bool
  let smallFlag: Binding<Bool>
  
  public init(slice: Slice, isSliceFlag: Bool, smallFlag: Binding<Bool>) {
    self.slice = slice
    self.isSliceFlag = isSliceFlag
    self.smallFlag = smallFlag
  }
  
  @Environment(SettingsModel.self) private var settings
  @Environment(ApiModel.self) private var apiModel
  
  public var body: some View {
    
    if isSliceFlag {
      // Flag on a Slice
      if smallFlag.wrappedValue {
        VStack(spacing: 5) {
          Line1SmallView(slice: slice, smallFlag: smallFlag)
          Line2SmallView(slice: slice)
        }
        .frame(width: smallFlag.wrappedValue ? 150 : 275)
        .background(settings.sliceBackground)

      } else {
        VStack(spacing: 5) {
          Line1View(slice: slice, smallFlag: smallFlag)
          Line2View(slice: slice)
          
          if let meter = apiModel.meterBy(shortName: .signal24Khz, slice: slice) {
            SMeterView(meter: meter)
          }
          ButtonView(slice: slice)
        }
        .frame(width: smallFlag.wrappedValue ? 150 : 275)
        .background(settings.sliceBackground)
      }

    } else {
      // Flag in Side Controls
      if let activeSlice = apiModel.activeSlice {
        VStack(spacing: 10) {
          Line1View(slice: activeSlice, smallFlag: smallFlag)
          Line2View(slice: activeSlice)
          if let meter = apiModel.meterBy(shortName: .signal24Khz, slice: activeSlice) {
            SMeterView(meter: meter)
          }
          ButtonView(slice: activeSlice)
        }
        .frame(width: smallFlag.wrappedValue ? 150 : 275)
        .background(settings.sliceBackground)

      } else {
        EmptyView()
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Major views

private struct Line1View: View {
  var slice: Slice
  @Binding var smallFlag: Bool
  
  @Environment(ApiModel.self) private var apiModel
  @Environment(SettingsModel.self) private var settings
  
  func filter(_ high: Int, _ low: Int) -> String {
    var width = Float(high - low)
    if width > 999 {
      width = width / 1_000
      return String(format: "%2.1f", width) + "k"
    }
    return String(format: "%3.0f", width)
  }
  
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "multiply.circle")
        .onTapGesture { apiModel.removeSlice(slice.id) }
      //        .disabled(slice == nil)
      
      //      HStack(spacing: 5) {
      //        Text("Tx")
      //        Text(slice.txAnt)
      //          .frame(width: 75)
      //          .controlSize(.small)
      //
      //          .popover(isPresented: Binding(get: { $0.showTxRxPopover}, set: .txRxClose ), arrowEdge: .bottom) {
      //            FlagAntennaView(store: Store(initialState: FlagAntenna.State()) { FlagAntenna() },
      //                            slice: slice)
      //          }
      
      //          .onTapGesture {
      //            viewStore.send(.showTxRx(slice))
      // FIXME:
      //          }
      //      }
      
      HStack {
        Text(filter(slice.filterHigh, slice.filterLow)).font(.system(size: 10))
        Text("SPLIT")
          .font(.title3)
          .foregroundColor(slice.splitId != nil ? .yellow : nil)
          .onTapGesture {  } // FIXME:
        Text("TX")
          .font(.title3)
          .foregroundColor(slice.txEnabled ? .red : nil)
          .onTapGesture { slice.setProperty(.txEnabled, (!slice.txEnabled).as1or0) }
        Text(slice.sliceLetter ?? "??")
          .font(.title3)
          .foregroundColor(slice.active ? settings.sliceActive : settings.sliceInactive)
          .onTapGesture { smallFlag.toggle() }
      }
    }
  }
}

private struct Line2View: View {
  var slice: Slice
  
  @Environment(ApiModel.self) private var apiModel
  
  var body: some View {
    HStack {
      Image(systemName: slice.locked ? "lock" : "lock.open")
        .onTapGesture {
          slice.setProperty(.locked, (!slice.locked).as1or0)
        }
      
      Group {
        Toggle(isOn: Binding(
          get: { slice.nbEnabled },
          set: { slice.setProperty(.nbEnabled, ($0).as1or0) })) { Text("NB") }
        Toggle(isOn: Binding(
          get: { slice.nrEnabled },
          set: { slice.setProperty(.nrEnabled, ($0).as1or0) })) { Text("NR") }
        Toggle(isOn: Binding(
          get: { slice.anfEnabled },
          set: { slice.setProperty(.anfEnabled, ($0).as1or0) })) { Text("ANF") }
//        Toggle(isOn: Binding(
//          get: { slice.qskEnabled},
//          set: { })) { Text("QSK") } 
        // FIXME:
      }
      .toggleStyle(.button)
      .controlSize(.mini)
      
      ApiIntView(hint: "frequency",
                 value: slice.frequency,
                 formatter: NumberFormatter.dotted,
                 action: { slice.setProperty(.frequency, $0.toMhz) },
                 isValid: { $0.isValidFrequency },
                 width: 90
      )
    }
  }
}

private struct SMeterView: View {
  var meter: Meter
  
  // calc the "S" level
  var sUnit: String {
    switch meter.value {
    case ..<(-121):       return " S0"
    case (-121)..<(-115): return " S1"
    case (-115)..<(-109): return " S2"
    case (-109)..<(-103): return " S3"
    case (-103)..<(-97):  return " S4"
    case (-103)..<(-97):  return " S5"
    case (-97)..<(-91):   return " S6"
    case (-91)..<(-85):   return " S7"
    case (-85)..<(-79):   return " S8"
    case (-79)..<(-73):   return " S9"
    case (-73)..<(-67):   return "+10"
    case (-67)..<(-61):   return "+20"
    case (-61)..<(-55):   return "+30"
    case (-55)..<(-49):   return "+40"
    case (-49)...:        return "+++"
    default:              return ""
    }
  }
  
  var level: Float {
    return Float((meter.value + 127) / 6)
  }
  
  var body: some View {
    HStack {
      LevelIndicatorView(levels: SignalLevel(rms: level, peak: 0), type: .sMeter)
      Text(sUnit)
        .monospaced()
        .frame(width: 30)
    }
  }
}


private struct ButtonView: View {
  var slice: Slice
  
  @Environment(ApiModel.self) private var apiodel
  
  @State var selection: FlagMode = .none
  
  var body: some View {
    
    ControlGroup {
      Button(FlagMode.aud.rawValue.uppercased()) { selection = selection == .aud ? .none : .aud }
      Button(FlagMode.dsp.rawValue.uppercased()) { selection = selection == .dsp ? .none : .dsp }
      Button(FlagMode.mode.rawValue.uppercased()) { selection = selection == .mode ? .none : .mode }
      Button(FlagMode.xrit.rawValue.uppercased()) { selection = selection == .xrit ? .none : .xrit }
      Button(FlagMode.dax.rawValue.uppercased()) { selection = selection == .dax ? .none : .dax }
    }.controlSize(.small)
    
    switch selection {
    case .aud:    AudView(slice: slice)
    case .dsp:    DspView(slice: slice)
    case .mode:   ModeView(slice: slice)
    case .xrit:   XritView(slice: slice)
    case .dax:    DaxView(slice: slice)
    case .none:   EmptyView()
    }
  }
}

private struct Line1SmallView: View {
  var slice: Slice
  @Binding var smallFlag: Bool
  
  @Environment(SettingsModel.self) private var settings
  @Environment(ApiModel.self) private var apiModel
  
  func filter(_ high: Int, _ low: Int) -> String {
    var width = Float(high - low)
    if width > 999 {
      width = width / 1_000
      return String(format: "%2.1f", width) + "k"
    }
    return String(format: "%3.0f", width)
  }
  
  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "multiply.circle")
        .onTapGesture { apiModel.removeSlice(slice.id) }
      //        .disabled(slice == nil)
      
      HStack {
        Text(filter(slice.filterHigh, slice.filterLow)).font(.system(size: 10))
        Group {
          Text("SPLIT")
            .foregroundColor(slice.splitId != nil ? .yellow : nil)
            .onTapGesture {  } // FIXME:
          Text("TX")
            .foregroundColor(slice.txEnabled ? .red : nil)
            .onTapGesture { slice.setProperty(.txEnabled, (!slice.txEnabled).as1or0) }
          Text("A")
            .foregroundColor(slice.active ? settings.sliceActive : settings.sliceInactive)
            .onTapGesture { smallFlag.toggle() }
        }.font(.title3)
      }
    }
  }
}

private struct Line2SmallView: View {
  var slice: Slice
  
  var body: some View {
    HStack {
      Image(systemName: slice.locked ? "lock" : "lock.open")
        .onTapGesture {
          slice.setProperty(.locked, (!slice.locked).as1or0)
        }
      
      ApiIntView(hint: "frequency",
                 value: slice.frequency,
                 formatter: NumberFormatter.dotted,
                 action: { slice.setProperty(.frequency, $0.toMhz) },
                 isValid: { $0.isValidFrequency },
                 width: 90
      )
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

#Preview {
  FlagView(slice: Slice(1), isSliceFlag: false, smallFlag: .constant(false))
    .frame(width: 275)
}
