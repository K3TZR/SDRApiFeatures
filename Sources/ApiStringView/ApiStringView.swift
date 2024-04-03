//
//  ApiStringView.swift
//  ViewFeatures/ApiStringView
//
//  Created by Douglas Adams on 2/19/23.
//

import SwiftUI

public struct ApiStringView: View {
  let hint: String
  let value: String
  let action: (String) -> Void
  let isValid: (String) -> Bool
  let width: CGFloat
  let height: CGFloat
  let font: Font
  let bordered: Bool
  
  public init
  (
    hint: String = "",
    value: String,
    action: @escaping (String) -> Void,
    isValid: @escaping (String) -> Bool = { _ in true },
    width: CGFloat = 100,
    height: CGFloat = 20,
    font: Font = .body,
    bordered: Bool = false
  )
  {
    self.hint = hint
    self.value = value
    self.action = action
    self.isValid = isValid
    self.width = width
    self.height = height
    self.font = font
    self.bordered = bordered
  }
  
  @State var valueString = ""
  @State var entryMode = false
  
  @FocusState private var entryFocus: Bool

  public var body: some View {
    if entryMode {
      // Editable view
      TextField(hint, text: $valueString)
        .focusable()
        .focused($entryFocus)
        .font(font)
        .frame(width: width)
      
        .onAppear {
          // force focus & selection
          self.entryFocus = true
        }
      
        .onChange(of: valueString) {
          // validate as each digit is enterred
          if !isValid($1) {
            valueString = String(valueString.dropLast(1))
            NSSound.beep()
          }
        }
      
        .onExitCommand {
          // abort (ESC key)
          entryMode = false
          entryFocus = false
        }
      
        .onSubmit {
          // submit (ENTER key)
          action(valueString)
          entryMode = false
          entryFocus = false
        }
      
    } else {
      ZStack {
        // Fixed view
        Text(value)
          .font(font)
          .frame(width: width, height: height, alignment: .leading)
          .overlay(
              bordered ?
              Rectangle()
                .stroke(.secondary, lineWidth:1)
              : nil)

          .onAppear {
            if value.isEmpty {
              // force focus & selection
              self.entryFocus = true
              valueString = value
              entryMode = true
            }
          }

        // Tap target
        Rectangle()
          .foregroundColor(.clear)
          .frame(width: width, height: height)
          .contentShape(Rectangle()) 
          .onTapGesture {
            // switch to Editable view
            valueString = value
            entryMode = true
          }

      }
    }
  }
}

struct ApiStringView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ApiStringView(hint: "name", value: "Doug's Flex", action: { print("value = \($0)") }, isValid: {_ in true }, width: 140, font: .title3 )
      
      ApiStringView(value: "K3TZR", action: { print("value = \($0)") } )
      
    }.frame(width: 200, height: 50)
  }
}
