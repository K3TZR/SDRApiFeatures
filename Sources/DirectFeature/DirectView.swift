//
//  DirectView.swift
//  
//
//  Created by Douglas Adams on 1/8/24.
//

import ComposableArchitecture
import Network
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct DirectView: View {
  @Bindable var store: StoreOf<DirectFeature>
  
  public init(store: StoreOf<DirectFeature>) {
    self.store = store
  }
  
  @Environment(\.dismiss) var dismiss
  
  public var body: some View {
    
    VStack(spacing: 10) {
      Text( store.heading ).font( .title2 )
      if store.message != nil { Text(store.message!).font(.subheadline) }
      Divider()
      HStack {
        Text( "IP Address" ).frame( width: store.labelWidth, alignment: .leading)
        TextField( "", text: $store.ip)
      }

      HStack( spacing: 60 ) {
        Button( "Cancel" ) {
          store.send(.cancelButtonTapped)
          dismiss()
        }
        .keyboardShortcut( .cancelAction )
        
        Button( "Save" ) {
          store.send(.saveButtonTapped(store.ip))
          dismiss()
        }
        .disabled( !store.ip.isValidIpAddress )
        .keyboardShortcut( .defaultAction )
      }
    }
    .frame( minWidth: store.overallWidth )
    .padding(10)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

#Preview {
  DirectView(store: Store(initialState: DirectFeature.State(ip: "192.168.1.200")) {
    DirectFeature()
  })
}

extension String {
  var isValidIpAddress: Bool {
    return self.matches(pattern: "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$")
  }
  
  private func matches(pattern: String) -> Bool {
    return self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) != nil
  }
}
