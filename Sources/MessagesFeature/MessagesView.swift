//
//  MessagesView.swift
//
//  Created by Douglas Adams on 1/8/22.
//

import ComposableArchitecture
import SwiftUI

import SharedFeature
import TcpFeature

// ----------------------------------------------------------------------------
// MARK: - View

public struct MessagesView: View {
  let store: StoreOf<MessagesFeature>
  
  public init(store: StoreOf<MessagesFeature>) {
    self.store = store
  }
  
  @Namespace var topID
  @Namespace var bottomID
  
  func attributedText( _ text: String) -> AttributedString {
    var attString = AttributedString(text)
    // color it appropriately
    if text.prefix(1) == "C" { attString.foregroundColor = .systemGreen }                         // Commands
    if text.prefix(1) == "R" && text.contains("|0|") { attString.foregroundColor = .systemGray }  // Replies no error
    if text.prefix(1) == "R" && !text.contains("|0|") { attString.foregroundColor = .systemRed }  // Replies w/error
    if text.prefix(2) == "S0" { attString.foregroundColor = .systemOrange }                       // S0

    // highlight any filterText value
    if !store.filterText.isEmpty {
      if let range = attString.range(of: store.filterText) {
        attString[range].underlineStyle = .single
        attString[range].font = .boldSystemFont(ofSize: 18)
      }
    }
    return attString
  }
  
  func intervalFormat(_ interval: Double) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 6
    formatter.positiveFormat = " * ##0.000000"
    return formatter.string(from: NSNumber(value: interval))!
  }
  
  public var body: some View {
    
    VStack(alignment: .leading) {
      FilterMessagesView(store: store)
      
      if store.messagesModel.filteredMessages.count == 0 {
        VStack(alignment: .leading) {
          Spacer()
          HStack {
            Spacer()
            Text("TCP Messages will be displayed here")
            Spacer()
          }
          Spacer()
        }
        
      } else {
        ScrollViewReader { proxy in
          ScrollView([.vertical]) {
            Text("Top").hidden()
              .id(topID)
            Grid (alignment: .leading) {
              ForEach(store.messagesModel.filteredMessages.reversed(), id: \.id) { message in
                GridRow(alignment: .top) {
                  if store.showTimes { Text(intervalFormat(message.interval) ) }
                  Text(attributedText(message.text))
                }
              }
              .textSelection(.enabled)
              .font(.system(size: CGFloat(store.fontSize), weight: .regular, design: .monospaced))
            }
            Text("Bottom").hidden()
              .id(bottomID)
          }
          .onChange(of: store.gotoTop) {
            let id = $1 ? bottomID : topID
            proxy.scrollTo(id, anchor: $1 ? .bottomLeading : .topLeading)
          }
        }
      }
      Spacer()
      Divider().background(Color(.gray))
      BottomButtonsView(store: store)
    }
  }
}

private struct FilterMessagesView: View {
  @Bindable var store: StoreOf<MessagesFeature>
  var body: some View {
    
    HStack {
      Picker("Show Tcp Messages of type", selection: $store.filter.sending(\.filterChanged)) {
        ForEach(MessageFilter.allCases, id: \.self) {
          Text($0.rawValue).tag($0.rawValue)
        }
      }
      .pickerStyle(MenuPickerStyle())
      .frame(width: 300)
      
      Image(systemName: "x.circle").font(.title2)
        .onTapGesture {
          store.send(.clearFilterTextTapped)
        }
      
      TextField("filter text", text: $store.filterText.sending(\.filterTextChanged))
    }
  }
}

private struct BottomButtonsView: View {
  @Bindable var store: StoreOf<MessagesFeature>
  
  var body: some View {
    
    HStack {
      Toggle(isOn: $store.gotoTop.sending(\.gotoTopChanged)) {
        Image(systemName: store.gotoTop ? "arrow.up.square" : "arrow.down.square").font(.title)
      }

      Spacer()
      HStack {
        Toggle("Show Times", isOn: $store.showTimes.sending(\.showTimesChanged))
        Toggle("Show Pings", isOn: $store.showPings.sending(\.showPingsChanged))
      }

      Spacer()
      Button("Save") { store.send(.saveButtonTapped) }
      
      Spacer()
      HStack {
        Toggle("Clear on Start", isOn: $store.clearOnStart.sending(\.clearOnStartChanged))
        Toggle("Clear on Stop", isOn: $store.clearOnStop.sending(\.clearOnStopChanged))
      }
      
      Button("Clear") { store.send(.clearButtonTapped) }
    }
    .toggleStyle(.button)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  MessagesView(store: Store(initialState: MessagesFeature.State(filterText: "",
                                                                filter: .all,
                                                                fontSize: 12,
                                                                showTimes: true,
                                                                showPings: false,
                                                                clearOnStart: true,
                                                                clearOnStop: false)) {
    MessagesFeature()
  })
  .frame(minWidth: 1250, maxWidth: .infinity)
}
