//
//  Waterfall.swift
//  FlexApiFeature/Objects
//
//  Created by Douglas Adams on 5/31/15.
//

import Foundation

import SharedFeature
import VitaFeature
import XCGLogFeature

@MainActor
@Observable
public final class Waterfall: Identifiable {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) {
    self.id = id
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32

  public var autoBlackEnabled = false
  public var autoBlackLevel: UInt32 = 0
  public var blackLevel = 0
  public var clientHandle: UInt32 = 0
  public var colorGain = 0
  public var gradientIndex = 0
  public var lineDuration = 0
  public var panadapterId: UInt32?
  
  public var selectedGradient = Waterfall.gradients[0]

  public static let gradients = [
    "Basic",
    "Dark",
    "Deuteranopia",
    "Grayscale",
    "Purple",
    "Tritanopia"
  ]

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  public var _initialized = false

  // ----------------------------------------------------------------------------
  // MARK: - Public types
    
  public enum Property: String {
    case clientHandle         = "client_handle"   // New Api only
    
    // on Waterfall
    case autoBlackEnabled     = "auto_black"
    case blackLevel           = "black_level"
    case colorGain            = "color_gain"
    case gradientIndex        = "gradient_index"
    case lineDuration         = "line_duration"
    
    // unused here
    case available
    case band
    case bandZoomEnabled      = "band_zoom"
    case bandwidth
    case capacity
    case center
    case daxIq                = "daxiq"
    case daxIqChannel         = "daxiq_channel"
    case daxIqRate            = "daxiq_rate"
    case loopA                = "loopa"
    case loopB                = "loopb"
    case panadapterId         = "panadapter"
    case rfGain               = "rfgain"
    case rxAnt                = "rxant"
    case segmentZoomEnabled   = "segment_zoom"
    case wide
    case xPixels              = "x_pixels"
    case xvtr
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse Waterfall properties
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = Waterfall.Property(rawValue: property.key) else {
        // log it and ignore the Key
        log("Waterfall \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
        
      case .autoBlackEnabled:   autoBlackEnabled = property.value.bValue
      case .blackLevel:         blackLevel = property.value.iValue
      case .clientHandle:       clientHandle = property.value.handle ?? 0
      case .colorGain:          colorGain = property.value.iValue
      case .gradientIndex:      gradientIndex = property.value.iValue
      case .lineDuration:       lineDuration = property.value.iValue
      case .panadapterId:       panadapterId = property.value.streamId ?? 0
        // the following are ignwater.ored here
      case .available, .band, .bandwidth, .bandZoomEnabled, .capacity, .center, .daxIq, .daxIqChannel,
          .daxIqRate, .loopA, .loopB, .rfGain, .rxAnt, .segmentZoomEnabled, .wide, .xPixels, .xvtr:  break
      }
    }
    // is it initialized?
    if _initialized == false && panadapterId != 0 {
      // NO, it is now
      _initialized = true
      log("Waterfall \(id.hex): ADDED handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Public set property methods
  
  public func setProperty(_ property: Waterfall.Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Waterfall.Property, _ value: String) {
    ObjectModel.shared.sendTcp("display panafall set \(id.toHex()) \(property.rawValue)=\(value)")
  }
  
  /* ----- from FlexApi -----
   display panafall set 0x" + _stream_id.ToString("X") + " rxant=" + _rxant);
   display panafall set 0x" + _stream_id.ToString("X") + " rfgain=" + _rfGain);
   display panafall set 0x" + _stream_id.ToString("X") + " daxiq_channel=" + _daxIQChannel);
   display panafall set 0x" + _stream_id.ToString("X") + " fps=" + value);
   display panafall set 0x" + _stream_id.ToString("X") + " average=" + value);
   display panafall set 0x" + _stream_id.ToString("x") + " weighted_average=" + Convert.ToByte(_weightedAverage));
   display panafall set 0x" + _stream_id.ToString("X") + " loopa=" + Convert.ToByte(_loopA));
   display panafall set 0x" + _stream_id.ToString("X") + " loopb=" + Convert.ToByte(_loopB));
   display panafall set 0x" + _stream_id.ToString("X") + " line_duration=" + _fallLineDurationMs.ToString());
   display panafall set 0x" + _stream_id.ToString("X") + " black_level=" + _fallBlackLevel.ToString());
   display panafall set 0x" + _stream_id.ToString("X") + " color_gain=" + _fallColorGain.ToString());
   display panafall set 0x" + _stream_id.ToString("X") + " auto_black=" + Convert.ToByte(_autoBlackLevelEnable));
   display panafall set 0x" + _stream_id.ToString("X") + " gradient_index=" + _fallGradientIndex.ToString());
   display panafall remove 0x" + _stream_id.ToString("X"));
   */  
}
