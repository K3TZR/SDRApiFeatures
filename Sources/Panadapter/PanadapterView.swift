//
//  PanadapterView.swift
//
//
//  Created by Douglas Adams on 4/16/23.
//

import SwiftUI

import FlexApi
import SettingsModel
import SharedModel

// ----------------------------------------------------------------------------
// MARK: - View

public struct PanadapterView: View {
  var panadapter: Panadapter
  let leftWidth: CGFloat
  
  public init(panadapter: Panadapter, leftWidth: CGFloat) {
    self.panadapter = panadapter
    self.leftWidth = leftWidth
  }
  
  @Environment(SettingsModel.self) private var settings
  @Environment(ApiModel.self) private var apiModel
  
  let frequencyLegendHeight: CGFloat = 20
  let spacings = [
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
  ]
  let formats = [
    (1_000_000,"%01.0f"),
    (500_000,"%01.0f"),
    (100_000,"%01.0f"),
    (50_000,"%02.3f"),
    (40_000,"%02.3f"),
    (30_000,"%02.3f"),
    (20_000,"%02.3f"),
    (10_000,"%02.3f"),
    (5_000,"%02.3f"),
    (4_000,"%02.3f"),
    (3_000,"%02.3f"),
    (2_000,"%02.3f"),
    (1_000,"%02.3f")
  ]
  
  func slicesToleft(slices: [Slice]) -> String {
    return ""
  }
  
  public var body: some View {
    
    VSplitView {
      GeometryReader { g in
        VStack(alignment: .leading, spacing: 0) {
          
          ZStack(alignment: .leading) {
            // Spectrum
            if let stream = apiModel.panadapters[id: panadapter.id] {
              SpectrumView(panadapter: stream)
                .background(settings.background)
            }
            
            // Vertical lines
            FrequencyLinesView(panadapter: panadapter, spacings: spacings, leftWidth: leftWidth)
            
            // Horizontal lines
            DbmLinesView(panadapter: panadapter, size: g.size, frequencyLegendHeight: frequencyLegendHeight)
            
            // DbmLegend
            DbmLegendView(panadapter: panadapter, size: g.size, frequencyLegendHeight: frequencyLegendHeight)
            
            // Slice(s)
            ForEach(apiModel.slices) { slice in
              if slice.panadapterId == panadapter.id {
                // Slice is on this Panadapter
                if slice.frequency >= panadapter.center - panadapter.bandwidth/2 &&
                    slice.frequency <= panadapter.center + panadapter.bandwidth/2 {
                  // Slice within the panadapter frequency range
                  SliceView(panadapter: panadapter,
                            slice: slice,
                            isSliceFlag: true,
                            width: g.size.width)
                }
              }
            }
            
            LeftView(panadapter: panadapter)
            
            RightView(panadapter: panadapter, width: g.size.width)
            
            // Tnf(s)
            ForEach(apiModel.tnfs) { tnf in
              if tnf.frequency >= panadapter.center - panadapter.bandwidth/2 &&
                  tnf.frequency <= panadapter.center + panadapter.bandwidth/2 {
                // Tnf within the panadapter frequency range
                TnfView(panadapter: panadapter,
                        tnf: tnf,
                        radio: apiModel.radio!,
                        size: CGSize(width: g.size.width, height: g.size.height - frequencyLegendHeight))
              }
            }
          }.frame(height: g.size.height - frequencyLegendHeight)
          
          // Frequency Legend
          FrequencyLegendView(panadapter: panadapter,
                              size: g.size,
                              spacings: spacings,
                              formats: formats)
          .frame(height: frequencyLegendHeight)
        }
        
        .onChange(of: g.size) {
          panadapter.setProperty(.xPixels, String(Int(g.size.width)))
          panadapter.setProperty(.yPixels, String(Int(g.size.height - frequencyLegendHeight)))
        }
      }
    }
  }
}

private struct LeftView: View {
  var panadapter: Panadapter
  
  @Environment(ApiModel.self) private var apiModel
  
  @MainActor var leftString: [String] {
    var letters = [String]()
    for slice in apiModel.slices {
      if slice.frequency < panadapter.center - panadapter.bandwidth/2 {
        letters.append(slice.sliceLetter ?? "??")
      }
    }
    return letters
  }
  
  public var body: some View {
    
    VStack {
      Spacer()
      if leftString.count == 0 {
        Text("")
      } else {
        Text("< " + leftString.joined(separator: ",")).font(.title)
          .offset(x: 40)
          .onTapGesture {
            print("----->>>>> ", "Tap on LEFT")
            //                viewStore.send(.panadapterProperty(panadapter, .center, slice.frequency.hzToMhz))
          }
      }
      Spacer()
    }
  }
}

private struct RightView: View {
  var panadapter: Panadapter
  var width: CGFloat
  
  @Environment(ApiModel.self) private var apiModel
  
  @MainActor var rightString: [String] {
    var letters = [String]()
    for slice in apiModel.slices {
      if slice.frequency > panadapter.center + panadapter.bandwidth/2 {
        letters.append(slice.sliceLetter ?? "??")
      }
    }
    return letters
  }
  
  public var body: some View {
    
    VStack {
      Spacer()
      if rightString.count == 0 {
        Text("")
      } else {
        Text("> " + rightString.joined(separator: ",")).font(.title)
          .offset(x: width - 80)
          .onTapGesture {
            print("----->>>>> ", "Tap on RIGHT")
            //              viewStore.send(.panadapterProperty(panadapter, .center, slice.frequency.hzToMhz))
          }
      }
      Spacer()
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  PanadapterView(panadapter: Panadapter(0x49999990), leftWidth: 0)
  .frame(width:800, height: 600)
}
