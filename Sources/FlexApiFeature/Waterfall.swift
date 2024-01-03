//
//  Waterfall.swift
//  ApiFeatures/Objects
//
//  Created by Douglas Adams on 5/31/15.
//

import Foundation

import SharedFeature
import VitaFeature

@MainActor
//@Observable
public final class Waterfall: Identifiable, Equatable {
  public nonisolated static func == (lhs: Waterfall, rhs: Waterfall) -> Bool {
    lhs.id == rhs.id
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) { self.id = id }
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public var isStreaming = false
  public var waterfallFrame: WaterfallFrame?

  public var autoBlackEnabled = false
  public var autoBlackLevel: UInt32 = 0
  public var blackLevel = 0
  public var clientHandle: UInt32 = 0
  public var colorGain = 0
//  public var delegate: StreamHandler?
  public var gradientIndex = 0
  public var lineDuration = 0
  public var panadapterId: UInt32?
  
  public var selectedGradient = Waterfall.gradients[0]
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var initialized = false
  
  public static let gradients = [
    "Basic",
    "Dark",
    "Deuteranopia",
    "Grayscale",
    "Purple",
    "Tritanopia"
  ]

  private static let kNumberOfFrames = 10

  private struct PayloadHeader {    // struct to mimic payload layout
    var firstBinFreq: UInt64        // 8 bytes
    var binBandwidth: UInt64        // 8 bytes
    var lineDuration : UInt32       // 4 bytes
    var segmentBinCount: UInt16     // 2 bytes
    var height: UInt16              // 2 bytes
    var frameNumber: UInt32         // 4 bytes
    var autoBlackLevel: UInt32      // 4 bytes
    var frameBinCount: UInt16       // 2 bytes
    var startingBinNumber: UInt16   // 2 bytes
  }
  
  private var _accumulatedBins = 0
  private var _expectedFrameNumber = -1
  private var _frames = [WaterfallFrame](repeating: WaterfallFrame(), count:kNumberOfFrames )
  private var _index: Int = 0
  private var _segmentBinCount = 0
  private var _startingBinNumber = 0

//  public enum Gradients: String {
//    case basic = "Basic"
//    case dark = "Dark"
//    case deuteranopia = "Deuteranopia"
//    case grayscale = "Grayscale"
//    case purple = "Purple"
//    case tritanopia = "Tritanopia"
//  }
  
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
  
  public func setIsStreaming() {
    Task { await MainActor.run { isStreaming = true }}
  }

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
  private let _api = ApiModel.shared
//  private let _objectModel = ObjectModel.shared

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
    if initialized == false && panadapterId != 0 {
      // NO, it is now
      initialized = true
      log("Waterfall \(id.hex): ADDED handle = \(clientHandle.hex)", .debug, #function, #file, #line)
    }
  }
  
  
  
  /// Process the Waterfall Vita struct
  ///      The payload of the incoming Vita struct is converted to a WaterfallFrame and
  ///      passed to the Waterfall Stream Handler
  /// - Parameters:
  ///   - vita:       a Vita struct
  public func vitaProcessor(_ vita: Vita) {
    if isStreaming == false {
      isStreaming = true
      
      // log the start of the stream
      log("Waterfall \(vita.streamId.hex) stream: STARTED", .info, #function, #file, #line)

//      Task { await MainActor.run { waterfalls[id: vita.streamId]?.setIsStreaming() }}
    }
    
    // Bins are just beyond the payload
    let byteOffsetToBins = MemoryLayout<PayloadHeader>.size
    
    vita.payloadData.withUnsafeBytes { ptr in
      // map the payload to the Payload struct
      let hdr = ptr.bindMemory(to: PayloadHeader.self)
      
      // validate the packet (could be incomplete at startup)
      _startingBinNumber = Int(CFSwapInt16BigToHost(hdr[0].startingBinNumber))
      _segmentBinCount = Int(CFSwapInt16BigToHost(hdr[0].segmentBinCount))
      _frames[_index].frameBinCount = Int(CFSwapInt16BigToHost(hdr[0].frameBinCount))
      _frames[_index].frameNumber = Int(CFSwapInt32BigToHost(hdr[0].frameNumber))
      
      if _frames[_index].frameBinCount == 0 { return }
      if _startingBinNumber + _segmentBinCount > _frames[_index].frameBinCount { return }
      
      // populate frame values
      _frames[_index].firstBinFreq = CGFloat(CFSwapInt64BigToHost(hdr[0].firstBinFreq)) / 1.048576E6
      _frames[_index].binBandwidth = CGFloat(CFSwapInt64BigToHost(hdr[0].binBandwidth)) / 1.048576E6
      _frames[_index].lineDuration = Int( CFSwapInt32BigToHost(hdr[0].lineDuration) )
      _frames[_index].height = Int( CFSwapInt16BigToHost(hdr[0].height) )
      _frames[_index].autoBlackLevel = CFSwapInt32BigToHost(hdr[0].autoBlackLevel)
      
      // are we waiting for the start of a frame?
      if _expectedFrameNumber == -1 {
        // YES, is it the start of a frame?
        if _startingBinNumber == 0 {
          // YES, START OF A FRAME
          _expectedFrameNumber = _frames[_index].frameNumber
        } else {
          // NO, NOT THE START OF A FRAME
          return
        }
      }
      // is it the expected frame?
      if _expectedFrameNumber != _frames[_index].frameNumber {
        // NOT THE EXPECTED FRAME, wait for the next start of frame
        log("Waterfall: missing frame(s), expected = \(_expectedFrameNumber), received = \(_frames[_index].frameNumber), accumulatedBins = \(_accumulatedBins), frameBinCount = \(_frames[_index].frameBinCount)", .debug, #function, #file, #line)
        _expectedFrameNumber = -1
        _accumulatedBins = 0
        
//        Task { await MainActor.run { streamStatus[id: vita.classCode]?.errors += 1 }}
        
        return
      }
      // copy the data
      vita.payloadData.withUnsafeBytes { ptr in
        // Swap the byte ordering of the data & place it in the bins
        for i in 0..<_segmentBinCount {
          _frames[_index].bins[i+_startingBinNumber] = CFSwapInt16BigToHost( ptr.load(fromByteOffset: byteOffsetToBins + (2 * i), as: UInt16.self) )
        }
      }
      _accumulatedBins += _segmentBinCount

      // is it a complete Frame?
      if _accumulatedBins == _frames[_index].frameBinCount {
        // updated just to be consistent (so that downstream won't use the wrong count)

        // YES, post it
        waterfallFrame = _frames[_index]

        // update the expected frame number & dataframe index
        _expectedFrameNumber += 1
        _accumulatedBins = 0
        _index = (_index + 1) % Waterfall.kNumberOfFrames
      }
    }
  }

  
  
  
  
  public func setProperty(_ property: Waterfall.Property, _ value: String) {
    parse([(property.rawValue, value)])
    send(property, value)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Waterfall.Property, _ value: String) {
    _api.sendCommand("display panafall set \(id.toHex()) \(property.rawValue)=\(value)")
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
