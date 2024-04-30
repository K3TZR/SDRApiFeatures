//
//  PanafallView.swift
//
//
//  Created by Douglas Adams on 5/20/23.
//
import ComposableArchitecture
import SwiftUI

import FlexApiFeature
import PanadapterFeature
import WaterfallFeature

public struct PanafallView: View {
  @Bindable var store: StoreOf<PanafallCore>
  
  public init(store: StoreOf<PanafallCore>) {
    self.store = store
  }

  @MainActor var leftSideWidth: CGFloat {
    store.panafallLeftSideIsOpen ? 60 : 0
  }
  
  @State var leftSideIsOpen = false
  
  public var body: some View {
    HSplitView {
      if store.panafallLeftSideIsOpen {
        VStack {
          TopButtonsView(store: store)
          Spacer()
          BottomButtonsView(store: store)
        }
        .frame(width: leftSideWidth)
        .padding(.vertical, 10)
      }
      
      ZStack(alignment: .topLeading) {
        
        VSplitView {
          PanadapterView(panadapter: store.panadapter, leftWidth: leftSideWidth)
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
          
          WaterfallView(panadapter: store.panadapter, leftWidth: leftSideWidth)
            .frame(minWidth: 500, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
        }
        
        VStack {
          HStack {
            Spacer()
            Label("Rx", systemImage: "antenna.radiowaves.left.and.right").opacity(0.5)
            Text(store.panadapter.rxAnt).font(.title).opacity(0.5)
              .padding(.trailing, 50)
          }
          
          if store.panadapter.rfGain != 0 {
            HStack(spacing: 5) {
              Spacer()
              Group {
                Text(store.panadapter.rfGain, format: .number)
                Text("Dbm").padding(.trailing, 50)
              }.font(.title).opacity(0.5)
            }
          }
          
          if store.panadapter.wide {
            HStack {
              Spacer()
              Text("WIDE").font(.title).opacity(0.5)
                .padding(.trailing, 50)
            }
          }
        }
        
        if store.panafallLeftSideIsOpen == false {
          Image(systemName: "arrowshape.right").font(.title)
            .offset(x: 20, y: 10)
            .onTapGesture {
              store.panafallLeftSideIsOpen.toggle()
            }
        }
      }
    }
  }
}

private struct TopButtonsView: View {
  @Bindable var store: StoreOf<PanafallCore>
  
//  var panadapter: Panadapter
//  let leftSideIsOpen: Binding<Bool>
  
  @Environment(ApiModel.self) var apiModel
  
  @State var bandPopover = false
  @State var antennaPopover = false
  @State var displayPopover = false
  @State var daxPopover = false

  var body: some View {
    VStack(alignment: .center, spacing: 20) {
      Image(systemName: "arrowshape.left").font(.title)
        .onTapGesture {
          store.panafallLeftSideIsOpen.toggle()
        }
      Image(systemName: "xmark.circle").font(.title)
        .onTapGesture {
          apiModel.removePanadapter(store.panadapter.id)
        }
      Button("Band") { bandPopover.toggle() }
        .popover(isPresented: $bandPopover , arrowEdge: .trailing) {
          BandView(store: store)
        }
      
      Button("Ant") { antennaPopover.toggle() }
        .popover(isPresented: $antennaPopover, arrowEdge: .trailing) {
          AntennaView(store: store)
        }
      
      Button("Disp") { displayPopover.toggle() }
        .popover(isPresented: $displayPopover, arrowEdge: .trailing) {
          DisplayView(store: store)
        }
      Button("Dax") { daxPopover.toggle() }
        .popover(isPresented: $daxPopover, arrowEdge: .trailing) {
          DaxView(store: store)
        }
    }
  }
}

private struct BottomButtonsView: View {
  @Bindable var store: StoreOf<PanafallCore>
//  var panadapter: Panadapter
  
  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Image(systemName: "s.circle")
          .onTapGesture {
            store.panadapter.setZoom(.segment)
          }
        Image(systemName: "b.circle")
          .onTapGesture {
            store.panadapter.setZoom(.band)
          }
      }
      HStack {
        Image(systemName: "minus.circle")
          .onTapGesture {
            store.panadapter.setZoom(.minus)
          }
        Image(systemName: "plus.circle")
          .onTapGesture {
            store.panadapter.setZoom(.plus)
          }
      }
    }.font(.title2)
  }
}

#Preview {
  PanafallView(store: Store(initialState: PanafallCore.State(panadapter: Panadapter(1), waterfall: Waterfall(1))) {
    PanafallCore()
  })
}
