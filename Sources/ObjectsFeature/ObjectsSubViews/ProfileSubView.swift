//
//  ProfileSubView.swift
//  Api6000/SubViews
//
//  Created by Douglas Adams on 8/9/22.
//

import ComposableArchitecture
import SwiftUI

import FlexApiFeature

// ----------------------------------------------------------------------------
// MARK: - View

struct ProfileSubView: View {

  @Environment(ApiModel.self) private var apiModel

  var body: some View {
    
    if apiModel.profiles.count == 0 {
      Grid(alignment: .leading, horizontalSpacing: 10) {
        GridRow {
          Group {
            Text("PROFILEs")
            Text("None present").foregroundColor(.red)
          }.frame(width: 100, alignment: .leading)
        }
      }
      
    } else {
      Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
        HeadingView()
        ForEach(apiModel.profiles) { profile in
          DetailView(profile: profile)
        }
      }
      .padding(.leading, 40)
    }
  }
}

private struct HeadingView: View {
  
  var body: some View {
    GridRow {
      Text("PROFILE").frame(width: 60, alignment: .leading)
      Text("Current").frame(width: 150, alignment: .leading)
      Text("List")
    }
  }
}

private struct DetailView: View {
  var profile: Profile
  
  var body: some View {
    GridRow {
      Text(profile.id.uppercased()).frame(width: 60, alignment: .leading)
      Text(profile.current).frame(width: 150, alignment: .leading)
      
      let list = profile.list.reduce("", { $0 + $1 + ","})
      Text(list).frame(width: 850, alignment: .leading)
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview

#Preview {
  ProfileSubView()
    .environment(ApiModel.shared)
}
