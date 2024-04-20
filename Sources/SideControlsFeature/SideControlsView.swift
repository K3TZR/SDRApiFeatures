//
//  ControlsView.swift
//  ControlsFeature/ControlsFeature
//
//  Created by Douglas Adams on 11/13/22.
//

import ComposableArchitecture
import SwiftUI




import FlexApiFeature
import SharedFeature

// ----------------------------------------------------------------------------
// MARK: - View

public struct ControlsView: View {
  @Bindable var store: StoreOf<SideControlsFeature>
  
  public init(store: StoreOf<SideControlsFeature>) {
    self.store = store
  }
  
  @Environment(ApiModel.self) private var apiModel

  private func toggleOption(_ selection: ControlsOptions) {
    if store.controlsSelections.contains(selection) {
      store.controlsSelections.remove(selection)
    } else {
      store.controlsSelections.insert(selection)
    }
    
  }
  
  public var body: some View {
    
    VStack(alignment: .center) {
      HStack {
        ControlGroup {
          //            Toggle("Rx", isOn: viewStore.binding(get: { $0.rxState != nil }, send: .rxButton ))
          Toggle("Tx", isOn: Binding(get: { store.controlsSelections.contains(.tx) }, set: {_,_  in toggleOption(.tx) } ))
          Toggle("Ph1", isOn: Binding(get: { store.controlsSelections.contains(.ph1)  }, set: {_,_  in toggleOption(.ph1) } ))
          Toggle("Ph2", isOn: Binding(get: { store.controlsSelections.contains(.ph2)  }, set: {_,_  in toggleOption(.ph2) } ))
          Toggle("Cw", isOn: Binding(get: { store.controlsSelections.contains(.cw)  }, set: {_,_  in toggleOption(.cw) } ))
          Toggle("Eq", isOn: Binding(get: { store.controlsSelections.contains(.eq)  }, set: {_,_  in toggleOption(.eq) } ))
        }
        .frame(width: 280)
//        .disabled(apiModel.clientInitialized == false)
      }
      Spacer()
      
      ScrollView {
//        if apiModel.clientInitialized {
          VStack {
            if store.controlsSelections.contains(.tx) { TxView() }
            if store.controlsSelections.contains(.ph1) { Ph1View() }
            if store.controlsSelections.contains(.ph2) { Ph2View() }
            if store.controlsSelections.contains(.cw) { CwView() }
            if store.controlsSelections.contains(.eq) { EqView(store: store) }
          }
          .padding(.horizontal, 10)
          
//        } else {
//          EmptyView()
//        }
      }
      //      .onChange(of: apiModel.clientInitialized) {
      //        viewStore.send(.openClose($1))
      //      }
    }
    .frame(width: 275)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  ControlsView(store: Store(initialState: SideControlsFeature.State()) {
    SideControlsFeature()
  })
  .environment(ApiModel.shared)
  
  .frame(width: 275)
}
