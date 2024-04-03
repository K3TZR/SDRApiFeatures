//
//  PanafallView.swift
//
//
//  Created by Douglas Adams on 5/20/23.
//

import SwiftUI

import FlexApi
import Panadapter
import Waterfall

public struct PanafallView: View {
  var panadapter: Panadapter
  
  public init(panadapter: Panadapter) {
    self.panadapter = panadapter
  }
  
  private let leftSideWidth: CGFloat = 60
  @State var leftSideIsOpen = false
  
  public var body: some View {
    HSplitView {
      if leftSideIsOpen {
        VStack {
          TopButtonsView(panadapter: panadapter, leftSideIsOpen: $leftSideIsOpen)
          Spacer()
          BottomButtonsView(panadapter: panadapter)
        }
        .frame(width: leftSideWidth)
        .padding(.vertical, 10)
      }
      
      ZStack(alignment: .topLeading) {
        
        VSplitView {
          PanadapterView(panadapter: panadapter, leftWidth: leftSideIsOpen ? leftSideWidth : 0)
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
          
          WaterfallView(panadapter: panadapter, leftWidth: leftSideIsOpen ? leftSideWidth : 0)
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
        }
        
        VStack {
          HStack {
            Spacer()
            Label("Rx", systemImage: "antenna.radiowaves.left.and.right").opacity(0.5)
            Text(panadapter.rxAnt).font(.title).opacity(0.5)
              .padding(.trailing, 50)
          }
          
          if panadapter.rfGain != 0 {
            HStack(spacing: 5) {
              Spacer()
              Group {
                Text(panadapter.rfGain, format: .number)
                Text("Dbm").padding(.trailing, 50)
              }.font(.title).opacity(0.5)
            }
          }
          
          if panadapter.wide {
            HStack {
              Spacer()
              Text("WIDE").font(.title).opacity(0.5)
                .padding(.trailing, 50)
            }
          }
        }
        
        if leftSideIsOpen == false {
          Image(systemName: "arrowshape.right").font(.title)
            .offset(x: 20, y: 10)
            .onTapGesture {
              leftSideIsOpen.toggle()
            }
        }
      }
    }
  }
}

private struct TopButtonsView: View {
  var panadapter: Panadapter
  let leftSideIsOpen: Binding<Bool>
  
  @Environment(ApiModel.self) var apiModel
  
  @State var bandPopover = false
  @State var antennaPopover = false
  @State var displayPopover = false
  @State var daxPopover = false

  var body: some View {
    VStack(alignment: .center, spacing: 20) {
      Image(systemName: "arrowshape.left").font(.title)
        .onTapGesture {
          leftSideIsOpen.wrappedValue.toggle()
        }
      Image(systemName: "xmark.circle").font(.title)
        .onTapGesture {
          apiModel.removePanadapter(panadapter.id)
        }
      Button("Band") { bandPopover.toggle() }
        .popover(isPresented: $bandPopover , arrowEdge: .trailing) {
          BandView( panadapter: panadapter)
        }
      
      Button("Ant") { antennaPopover.toggle() }
        .popover(isPresented: $antennaPopover, arrowEdge: .trailing) {
          AntennaView(panadapter: panadapter)
        }
      
      Button("Disp") { displayPopover.toggle() }
        .popover(isPresented: $displayPopover, arrowEdge: .trailing) {
          DisplayView(panadapter: panadapter)
        }
      Button("Dax") { daxPopover.toggle() }
        .popover(isPresented: $daxPopover, arrowEdge: .trailing) {
          DaxView(panadapter: panadapter)
        }
    }
  }
}

private struct BottomButtonsView: View {
  var panadapter: Panadapter
  
  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Image(systemName: "s.circle")
          .onTapGesture {
            panadapter.setZoom(.segment)
          }
        Image(systemName: "b.circle")
          .onTapGesture {
            panadapter.setZoom(.band)
          }
      }
      HStack {
        Image(systemName: "minus.circle")
          .onTapGesture {
            panadapter.setZoom(.minus)
          }
        Image(systemName: "plus.circle")
          .onTapGesture {
            panadapter.setZoom(.plus)
          }
      }
    }.font(.title2)
  }
}

#Preview {
  PanafallView(panadapter: Panadapter(0x49999990))
}
