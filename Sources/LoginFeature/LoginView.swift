//
//  LoginView.swift
//  ViewFeatures/LoginFeature
//
//  Created by Douglas Adams on 12/28/21.
//

import ComposableArchitecture
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct LoginView: View {
  @Bindable var store: StoreOf<LoginFeature>
  
  public init(store: StoreOf<LoginFeature>) {
    self.store = store
  }

  @Environment(\.dismiss) var dismiss
  
  @State var password = ""

  public var body: some View {
    VStack(spacing: 10) {
      Text( store.heading ).font( .title2 )
      if store.message != nil { Text(store.message!).font(.subheadline) }
      Divider()
      HStack {
        Text( store.userLabel ).frame( width: store.labelWidth, alignment: .leading)
        TextField( "", text: $store.user)
      }
      HStack {
        Text( store.pwdLabel ).frame( width: store.labelWidth, alignment: .leading)
        SecureField( "", text: $password)
      }
      
      HStack( spacing: 60 ) {
        Button( "Cancel" ) {
          store.send(.cancelButtonTapped)
          dismiss()
        }
          .keyboardShortcut( .cancelAction )
        
        Button( "Log in" ) { 
          store.send(.loginButtonTapped(store.user, password))
          dismiss() }
          .keyboardShortcut( .defaultAction )
          .disabled( store.user.isEmpty || password.isEmpty )
      }
    }
    .frame( minWidth: store.overallWidth )
    .padding(10)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

#Preview {
  LoginView(store: Store(initialState: LoginFeature.State(user: "Some User")) {
    LoginFeature()
  })
}

/*
 #Preview("Picker Gui") {
   PickerView(store: Store(initialState: PickerFeature.State(listener: Listener(), isGui: true, guiDefault: nil, nonGuiDefault: nil)) {
     PickerFeature()
   })
 }

 */
