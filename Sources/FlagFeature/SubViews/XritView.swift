//
//  SwiftUIView.swift
//  
//
//  Created by Douglas Adams on 6/25/23.
//

import SwiftUI

import ApiIntView
import FlexApi

struct XritView: View {
  var slice: Slice
  
  let buttonWidth: CGFloat = 40
  
  var body: some View {
    
    Grid(horizontalSpacing: 15) {
      GridRow {
        Toggle(isOn: Binding(
          get: { slice.ritEnabled},
          set: { slice.setProperty(.ritEnabled, $0.as1or0) })) { Text("RIT").frame(width: buttonWidth) }
          .toggleStyle(.button)
        
        HStack(spacing: 5) {
          Image(systemName: "plus.square").font(.title2)
            .onTapGesture {
              slice.setProperty(.ritOffset, String(slice.ritOffset + 10))
            }
          ApiIntView(hint: "rit", value: slice.ritOffset, action: { slice.setProperty(.ritOffset, String($0)) }, width: 50)
          Image(systemName: "minus.square").font(.title2)
            .onTapGesture {
              slice.setProperty(.ritOffset, String(slice.ritOffset - 10))
            }
        }
        Button(action: { slice.setProperty(.ritOffset, "0") }, label: { Text("Clear").frame(width: buttonWidth) })
      }
      GridRow {
        Toggle(isOn: Binding(
          get: { slice.xitEnabled},
          set: { slice.setProperty(.xitEnabled, $0.as1or0) })) { Text("XIT").frame(width: buttonWidth) }
          .toggleStyle(.button)
        
        HStack(spacing: 5) {
          Image(systemName: "plus.square").font(.title2)
            .onTapGesture {
              slice.setProperty(.xitOffset, String(slice.xitOffset + 10))
            }
          ApiIntView(hint: "xit", value: slice.xitOffset, action: { slice.setProperty(.xitOffset, String($0)) }, width: 50)
          Image(systemName: "minus.square").font(.title2)
            .onTapGesture {
              slice.setProperty(.xitOffset, String(slice.xitOffset - 10))
            }
        }
        Button(action: { slice.setProperty(.xitOffset, "0") }, label: { Text("Clear").frame(width: buttonWidth) })
      }
      GridRow {
        Text("Tuning step")
        HStack(spacing: 5) {
          Image(systemName: "plus.square").font(.title2)
            .onTapGesture {
              slice.setProperty(.step, String(slice.step + 10))
            }
          ApiIntView(hint: "step", value: slice.step, action: { slice.setProperty(.step, String($0)) }, width: 50)
          Image(systemName: "minus.square").font(.title2)
            .onTapGesture {
              slice.setProperty(.step, String(slice.step - 10))
            }
        }
        
        //                        .modifier(ClearButton(boundText: $tuningStepString, trailing: false))
        //        Stepper("", value: viewStore.binding(
        //          get: {_ in slice.step},
        //          send: { .sliceSetAndSend(slice, .step, String($0)) } ), in: 0...100000)
      }
    }
  }
}
