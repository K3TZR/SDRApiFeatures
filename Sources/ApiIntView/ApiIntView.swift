//
//  ApiIntView.swift
//  ViewFeatures/ApiIntView
//
//  Created by Douglas Adams on 2/19/23.
//

import SwiftUI

public struct ApiIntView: View {
  let hint: String
  let value: Int
  let formatter: NumberFormatter
  let action: (String) -> Void
  let isValid: (String) -> Bool
  let width: CGFloat
  let height: CGFloat
  let font: Font
  let bordered: Bool
  
  public init
  (
    hint: String = "",
    value: Int,
    formatter: NumberFormatter = NumberFormatter(),
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
    self.formatter = formatter
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
        .multilineTextAlignment(.trailing)
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
        }
      
        .onSubmit {
          // submit (ENTER key)
          action(valueString)
          entryMode = false
        }
      
    } else {
      ZStack {
        // Fixed view
        Text(formatter.string(from: value as NSNumber)!)
          .font(font)
          .frame(width: width, height: height, alignment: .trailing)
          .overlay(
              bordered ?
              Rectangle()
                .stroke(.secondary, lineWidth:1)
              : nil)

        // Tap target
        Rectangle()
          .foregroundColor(.clear)
          .frame(width: width, height: height)
          .contentShape(Rectangle())
          .onTapGesture {
            // switch to Editable view
            valueString = NumberFormatter().string(from: value as NSNumber)!
            entryMode = true
          }
      }
    }
  }
}

//#Preview ("ApiIntView"){
//  var formatter: NumberFormatter {
//    let formatter = NumberFormatter()
//    formatter.groupingSeparator = "."
//    formatter.numberStyle = .decimal
//    return formatter
//  }
//  
//  ApiIntView(hint: "frequency", value: 14_200_000, formatter: formatter, action: { print("value = \($0)") }, isValid: {_ in true }, width: 140, font: .title3 )
//}
    
#Preview("ApiIntView") {
  ApiIntView(value: 600, action: { print("value = \($0)") } )
}
