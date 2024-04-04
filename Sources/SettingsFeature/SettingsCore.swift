//
//  SettingsCore.swift
//
//
//  Created by Douglas Adams on 3/28/24.
//

import ComposableArchitecture
import Foundation
import SwiftUI

import FlexApiFeature
import SharedFeature

public enum TabSelection: String {
  case radio = "Radio"
  case network = "Network"
  case gps = "GPS"
  case tx = "Transmit"
  case phoneCw = "Phone CW"
  case xvtrs = "Xvtrs"
  case profiles = "Profiles"
  case colors = "Colors"
  case misc = "Misc"
  case connection = "Connection"
}

public enum ProfileSelection: String {
  case global = "Global"
  case mic = "Mic"
  case tx = "Tx"
}

@Reducer
public struct SettingsCore {
  public init() {}
  
  @ObservableState
  public struct State {
    
    public init() {}

    // ---------- GUI Settings ----------
    @Shared(.appStorage("alertOnError")) var alertOnError = false
    //    @Shared(.appStorage("altAntennaNames")) var altAntennaNames: [AntennaName]
    //    @Shared(.appStorage("cwxEnabled")) var cwxEnabled: Bool
    //    @Shared(.appStorage("daxPanelOptions")) var daxPanelOptions: DaxPanelOptions
    //    @Shared(.appStorage("dbSpacing")) var dbSpacing: Int
    //    @Shared(.appStorage("guiClientId")) var guiClientId: UUID?
    //    @Shared(.appStorage("markersEnabled")) var markersEnabled: Bool
    @Shared(.appStorage("monitorShortName")) var monitorShortName: String = Meter.ShortName.voltageAfterFuse.rawValue
    @Shared(.appStorage("openControls")) var openControls: Bool = false
    //    @Shared(.appStorage("selectedEqualizerId")) var selectedEqualizerId: String
//    @Shared(.appStorage("controlsOptions")) var controlsOptions: OptionSet = ControlsOptions.all
    @Shared(.appStorage("singleClickTuneEnabled")) var singleClickTuneEnabled: Bool = false
    @Shared(.appStorage("sliceMinimizedEnabled")) var sliceMinimizedEnabled: Bool = false
    //    @Shared(.appStorage("spectrumFillLevel")) var spectrumFillLevel: Double
    //    @Shared(.appStorage("spectrumType")) var spectrumType: String
    
    // --------- Mac Audio Settings ----------
    @Shared(.appStorage("remoteRxAudioCompressed")) var remoteRxAudioCompressed: Bool = true
    //    @Shared(.appStorage("remoteRxAudioEnabled")) var remoteRxAudioEnabled: Bool
    //    @Shared(.appStorage("remoteRxAudioMute")) var remoteRxAudioMute: Bool
    //    @Shared(.appStorage("remoteRxAudioOutputDeviceId")) var remoteRxAudioOutputDeviceId: Int
    //    @Shared(.appStorage("remoteRxAudioVolume")) var remoteRxAudioVolume: Float
    //    @Shared(.appStorage("remoteTxAudioEnabled")) var remoteTxAudioEnabled: Bool
    //    @Shared(.appStorage("remoteTxAudioInputDeviceId")) var remoteTxAudioInputDeviceId: Int
    
    // ---------- Broadcast Settings ----------
    @Shared(.appStorage("ignoreTimeStamps")) var ignoreTimeStamps: Bool = true
    @Shared(.appStorage("logBroadcasts")) var logBroadcasts: Bool = false
    
    // ---------- Connection Settings ----------
    //    @Shared(.appStorage("directEnabled")) var directEnabled: Bool
    //    @Shared(.appStorage("guiDefault")) var guiDefault: DefaultConnection?
    //    @Shared(.appStorage("isGui")) var isGui: Bool
    //    @Shared(.appStorage("localEnabled")) var localEnabled: Bool
    @Shared(.appStorage("loginRequired")) var loginRequired: Bool = false
    @Shared(.appStorage("mtuValue")) var mtuValue: Int = 1_500
    //    @Shared(.appStorage("nonGuiDefault")) var nonGuiDefault: DefaultConnection?
    //    @Shared(.appStorage("refreshToken")) var refreshToken: String?
    //    @Shared(.appStorage("requireSmartlinkLogin")) var requireSmartlinkLogin: Bool
    //    @Shared(.appStorage("smartlinkEnabled")) var smartlinkEnabled: Bool
    //    @Shared(.appStorage("smartlinkUser")) var smartlinkUser: String
    @Shared(.appStorage("stationName")) var stationName: String = "My Radio"
    @Shared(.appStorage("useDefault")) var useDefault: Bool = false
    @Shared(.appStorage("knownRadios")) var knownRadios = [KnownRadio]()
    
    // ---------- Color Settings ----------
    @Shared(.appStorage("background")) var background: Color = .black
    @Shared(.appStorage("dbLegend")) var dbLegend: Color = .green
    @Shared(.appStorage("dbLines")) var dbLines: Color = .white.opacity(0.3)
    @Shared(.appStorage("flagBackground")) var flagBackground: Color = .black
    @Shared(.appStorage("frequencyLegend")) var frequencyLegend: Color = .green
    @Shared(.appStorage("gridLines")) var gridLines: Color = .white.opacity(0.3)
    @Shared(.appStorage("marker")) var marker: Color = .yellow
    @Shared(.appStorage("markerEdge")) var markerEdge: Color = .red.opacity(0.2)
    @Shared(.appStorage("markerSegment")) var markerSegment: Color = .white.opacity(0.2)
    @Shared(.appStorage("sliceActive")) var sliceActive: Color = .yellow
    @Shared(.appStorage("sliceBackground")) var sliceBackground: Color = .black
    @Shared(.appStorage("sliceFilter")) var sliceFilter: Color = .white.opacity(0.2)
    @Shared(.appStorage("sliceInactive")) var sliceInactive: Color = .yellow
    @Shared(.appStorage("spectrumLine")) var spectrumLine: Color = .white
    @Shared(.appStorage("spectrumFill")) var spectrumFill: Color = .white
    @Shared(.appStorage("tnfDeep")) var tnfDeep: Color = .yellow.opacity(0.2)
    @Shared(.appStorage("tnfInactive")) var tnfInactive: Color = .white.opacity(0.2)
    @Shared(.appStorage("tnfNormal")) var tnfNormal: Color = .green.opacity(0.2)
    @Shared(.appStorage("tnfPermanent")) var tnfPermanent: Color = .white
    @Shared(.appStorage("tnfVeryDeep")) var tnfVeryDeep: Color = .red.opacity(0.2)
    @Shared(.appStorage("waterfallClear")) var waterfallClear: Color = .black
    
    // --------- DAX Settings ----------
    @Shared(.appStorage("daxReducedBandwidth")) var daxReducedBandwidth: Bool = false
    //    @Shared(.appStorage("daxMicSetting")) var daxMicSetting: DaxSetting
    //    @Shared(.appStorage("daxRxSetting")) var daxRxSetting: DaxSetting
    //    @Shared(.appStorage("daxTxSetting")) var daxTxSetting: DaxSetting
    
    // ---------- Spectrum Gradient Settings ----------
    //    @Shared(.appStorage("spectrumGradientColor0")) var spectrumGradientColor0: Color = .white.opacity(0.4)
    //    @Shared(.appStorage("spectrumGradientColor1")) var spectrumGradientColor1: Color = .green
    //    @Shared(.appStorage("spectrumGradientColor2")) var spectrumGradientColor2: Color = .yellow
    //    @Shared(.appStorage("spectrumGradientColor3")) var spectrumGradientColor3: Color = .red
    //    @Shared(.appStorage("spectrumGradientStop0")) var spectrumGradientStop0: Double = 0.2
    //    @Shared(.appStorage("spectrumGradientStop1")) var spectrumGradientStop1: Double = 0.4
    //    @Shared(.appStorage("spectrumGradientStop2")) var spectrumGradientStop2: Double = 0.5
    //    @Shared(.appStorage("spectrumGradientStop3")) var spectrumGradientStop3: Double = 0.6
    
    // ---------- Settings View Settings ----------
    @Shared(.appStorage("tabSelection")) var tabSelection: String = TabSelection.colors.rawValue
    @Shared(.appStorage("profileSelection")) var profileSelection: String = ProfileSelection.mic.rawValue
  }
  
  public enum Action: BindableAction {
    case binding(BindingAction<State>)
    
    case reset(String)
    case resetAll
    
  }
  
  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
        
      case let .reset(stringKey):
        print("reset:")
        reset(stringKey)
        return .none
        
      case .resetAll:
        print("resetAll")
        resetAll()
        return .none
        
      case .binding(_):
        return .none
      }
    }
  }
  
  private func reset(_ key: String) {
    UserDefaults.standard.removeObject(forKey: key)
  }
  
  private func resetAll() {
    UserDefaults.resetDefaults()
  }
  
  // reset a color to it's initial value
  //  private func reset(_ color: AppColor){
  //    // ---------- Colors ----------
  //    switch color {
  //    case .background: background = .black
  //    case .dbLegend: dbLegend = .green
  //    case .dbLines: dbLines = .white.opacity(0.3)
  //    case .frequencyLegend: frequencyLegend = .green
  //    case .gridLines: gridLines = .white.opacity(0.3)
  //    case .marker: marker = .yellow
  //    case .markerEdge: markerEdge = .red.opacity(0.2)
  //    case .markerSegment: markerSegment = .white.opacity(0.2)
  //    case .sliceActive: sliceActive = .red
  //    case .sliceFilter: sliceFilter = .white.opacity(0.2)
  //    case .sliceInactive: sliceInactive = .yellow
  //    case .spectrumLine: spectrumLine = .white
  //    case .spectrumFill: spectrumFill = .white
  //    case .tnfDeep: tnfDeep = .yellow.opacity(0.2)
  //    case .tnfInactive: tnfInactive = .white.opacity(0.2)
  //    case .tnfNormal: tnfNormal = .green.opacity(0.2)
  //    case .tnfPermanent: tnfPermanent = .white
  //    case .tnfVeryDeep: tnfVeryDeep = .red.opacity(0.2)
  //    }
  //  }
  
}

// ---------- UserDefaults Extension ----------
extension UserDefaults {
  static func resetDefaults() {
    if let bundleID = Bundle.main.bundleIdentifier {
      UserDefaults.standard.removePersistentDomain(forName: bundleID)
    }
  }
}
