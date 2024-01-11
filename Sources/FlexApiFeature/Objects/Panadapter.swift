//
//  Panadapter.swift
//  ApiFeatures/Objects
//
//  Created by Douglas Adams on 5/31/15.
//  Copyright (c) 2015 Douglas Adams, K3TZR
//

import Foundation

import SharedFeature
import VitaFeature

@MainActor
@Observable
public final class Panadapter: Identifiable, Equatable {
  public nonisolated static func == (lhs: Panadapter, rhs: Panadapter) -> Bool {
    lhs.id == rhs.id
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32, _ apiModel: ApiModel) {
    self.id = id
    _apiModel = apiModel
  }

  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  public var isStreaming = false
  public var panadapterFrame: PanadapterFrame?

  public var antList = [String]()
  public var clientHandle: UInt32 = 0
  public var dbmValues = [LegendValue]()
  public var fillLevel: Int = 0
  public var freqLegends = [Legend]()      // FIXME: remove when panadapter draw logic is updated
  public var freqOffset: CGFloat = 0
  public var maxBw: Hz = 0
  public var minBw: Hz = 0
  public var preamp = ""
  public var rfGainHigh = 0
  public var rfGainLow = 0
  public var rfGainStep = 0
  public var rfGainValues = ""
  public var waterfallId: UInt32 = 0
  public var wide = false
  public var wnbUpdating = false
  public var xvtrLabel = ""
  
  public var average: Int = 0
  public var band: String = ""
  // FIXME: Where does autoCenter come from?
  public var bandwidth: Hz = 0
  public var bandZoomEnabled: Bool  = false
  public var center: Hz = 0
  public var daxIqChannel: Int = 0
  public var fps: Int = 0
  public var loggerDisplayEnabled: Bool = false
  public var loggerDisplayIpAddress: String = ""
  public var loggerDisplayPort: Int = 0
  public var loggerDisplayRadioNumber: Int = 0
  public var loopAEnabled: Bool = false
  public var loopBEnabled: Bool = false
  public var maxDbm: CGFloat = 0
  public var minDbm: CGFloat = 0
  public var rfGain: Int = 0
  public var rxAnt: String = ""
  public var segmentZoomEnabled: Bool = false
  public var weightedAverageEnabled: Bool = false
  public var wnbEnabled: Bool = false
  public var wnbLevel: Int = 0
  public var xPixels: CGFloat = 0
  public var yPixels: CGFloat = 0
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  
  public let daxIqChoices = Radio.kDaxIqChannels
  public var initialized = false
  
  public enum Property: String {
    //   NOTE: the Radio sends these tokens to the API
    case antList                    = "ant_list"
    case average
    case band
    case bandwidth
    case bandZoomEnabled            = "band_zoom"
    case center
    case clientHandle               = "client_handle"
    case daxIq                      = "daxiq"
    case daxIqChannel               = "daxiq_channel"
//    case fillLevel
    case fps
    case loopAEnabled               = "loopa"
    case loopBEnabled               = "loopb"
    case maxBw                      = "max_bw"
    case maxDbm                     = "max_dbm"
    case minBw                      = "min_bw"
    case minDbm                     = "min_dbm"
    case preamp                     = "pre"
    case rfGain                     = "rfgain"
    case rxAnt                      = "rxant"
    case segmentZoomEnabled         = "segment_zoom"
    case waterfallId                = "waterfall"
    case weightedAverageEnabled     = "weighted_average"
    case wide
    case wnbEnabled                 = "wnb"
    case wnbLevel                   = "wnb_level"
    case wnbUpdating                = "wnb_updating"
    case xvtrLabel                  = "xvtr"
    
    //   NOTE: ignored here
    case available
    case capacity
    case daxIqRate                  = "daxiq_rate"
    case xpixels                    = "x_pixels"
    case ypixels                    = "y_pixels"

    //   NOTE: the Radio requires these tokens from the API
    case xPixels                    = "xpixels"
    case yPixels                    = "ypixels"
    
    //   NOTE: not sent in status messages
    case n1mmSpectrumEnable         = "n1mm_spectrum_enable"
    case n1mmAddress                = "n1mm_address"
    case n1mmPort                   = "n1mm_port"
    case n1mmRadio                  = "n1mm_radio"
  }
  
  public struct LegendValue: Identifiable {
    public var id: CGFloat         // relative position 0...1
    public var label: String       // value to display
    public var value: CGFloat      // actual value
    public var lineCount: CGFloat
  }

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _apiModel: ApiModel

  private struct PayloadHeader {      // struct to mimic payload layout
    var startingBinNumber: UInt16
    var segmentBinCount: UInt16
    var binSize: UInt16
    var frameBinCount: UInt16
    var frameNumber: UInt32
  }
  
  private var _accumulatedBins = 0
  private var _droppedPackets = 0
  private var _expectedFrameNumber = -1
  private var _frames = [PanadapterFrame](repeating: PanadapterFrame(), count: kNumberOfFrames)
  private var _index: Int = 0
  
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Static properties
  
  private static let kNumberOfFrames = 16
  private static let dbmMax: CGFloat = 20
  private static let dbmMin: CGFloat = -180
  
  // ----------------------------------------------------------------------------
  // MARK: - Public Parse methods
  
  /// Parse key/value pairs
  /// - Parameter properties:       a KeyValuesArray
  public func parse(_ properties: KeyValuesArray) {
    for property in properties {
      // check for unknown Keys
      guard let token = Panadapter.Property(rawValue: property.key) else {
        // unknown, log it and ignore the Key
        log("Panadapter \(id.hex): unknown property, \(property.key) = \(property.value)", .warning, #function, #file, #line)
        continue
      }
      // Known keys, in alphabetical order
      switch token {
      case .antList:                antList = property.value.list
      case .average:                average = property.value.iValue
      case .band:                   band = property.value
      case .bandwidth:              bandwidth = property.value.mhzToHz
      case .bandZoomEnabled:        bandZoomEnabled = property.value.bValue
      case .center:                 center = property.value.mhzToHz
      case .clientHandle:           clientHandle = property.value.handle ?? 0
      case .daxIq:                  daxIqChannel = property.value.iValue
      case .daxIqChannel:           daxIqChannel = property.value.iValue
      case .fps:                    fps = property.value.iValue
      case .loopAEnabled:           loopAEnabled = property.value.bValue
      case .loopBEnabled:           loopBEnabled = property.value.bValue
      case .maxBw:                  maxBw = property.value.mhzToHz
      case .maxDbm:                 maxDbm = min(property.value.cgValue, Panadapter.dbmMax)
      case .minBw:                  minBw = property.value.mhzToHz
      case .minDbm:                 minDbm = max(property.value.cgValue, Panadapter.dbmMin)
      case .preamp:                 preamp = property.value
      case .rfGain:                 rfGain = property.value.iValue
      case .rxAnt:                  rxAnt = property.value
      case .segmentZoomEnabled:     segmentZoomEnabled = property.value.bValue
      case .waterfallId:            waterfallId = property.value.streamId ?? 0
      case .wide:                   wide = property.value.bValue
      case .weightedAverageEnabled: weightedAverageEnabled = property.value.bValue
      case .wnbEnabled:             wnbEnabled = property.value.bValue
      case .wnbLevel:               wnbLevel = property.value.iValue
      case .wnbUpdating:            wnbUpdating = property.value.bValue
      case .xvtrLabel:              xvtrLabel = property.value
        
      case .available, .capacity, .daxIqRate, .xpixels, .ypixels:     break // ignored by Panadapter
      case .xPixels, .yPixels:                                        break // not sent in status messages
      case .n1mmSpectrumEnable, .n1mmAddress, .n1mmPort, .n1mmRadio:  break // not sent in status messages
//      case .fillLevel:                                                break // not sent in status messages
      }
    }
    // is it initialized?∫
    if initialized == false && center != 0 && bandwidth != 0 && (minDbm != 0.0 || maxDbm != 0.0) {
      // NO, it is now
      initialized = true
      log("Panadapter \(id.hex): ADDED, center = \(center.hzToMhz), bandwidth = \(bandwidth.hzToMhz)", .debug, #function, #file, #line)
      
      // FIXME: ????
      _apiModel.activePanadapter = self
    }
  }
  
  
  
  
  /// Process the Panadapter Vita struct
  ///      The payload of the incoming Vita struct is converted to a PanadapterFrame and
  ///      passed to the Panadapter Stream Handler
  ///
  /// - Parameters:
  ///   - vita:        a Vita struct
  public func vitaProcessor(_ vita: Vita) {
    if isStreaming == false {
      isStreaming = true
      
      // log the start of the stream
      log("Panadapter \(vita.streamId.hex) stream: STARTED", .info, #function, #file, #line)
      
      Task { await MainActor.run {  _apiModel.panadapters[id: vita.streamId]?.setIsStreaming() }}
    }
    
    // Bins are just beyond the payload
    let byteOffsetToBins = MemoryLayout<PayloadHeader>.size
    
    vita.payloadData.withUnsafeBytes { ptr in
      // map the payload to the Payload struct
      let hdr = ptr.bindMemory(to: PayloadHeader.self)

      _frames[_index].segmentStart = Int(CFSwapInt16BigToHost(hdr[0].startingBinNumber))
      _frames[_index].segmentSize = Int(CFSwapInt16BigToHost(hdr[0].segmentBinCount))
      _frames[_index].binSize = Int(CFSwapInt16BigToHost(hdr[0].binSize))
      _frames[_index].frameSize = Int(CFSwapInt16BigToHost(hdr[0].frameBinCount))
      _frames[_index].frameNumber = Int(CFSwapInt32BigToHost(hdr[0].frameNumber))

      
      
//      print("number", _frames[_index].frameNumber, "Start", _frames[_index].segmentStart, "size", _frames[_index].segmentSize, "toal size", _frames[_index].frameSize)
      
      

      // validate the packet (could be incomplete at startup)
      if _frames[_index].frameSize == 0 { return }
      if _frames[_index].segmentStart + _frames[_index].segmentSize > _frames[_index].frameSize { return }
      
      // are we waiting for the start of a frame?
      if _expectedFrameNumber == -1 {
        // YES, is it the start of a frame?
        if _frames[_index].segmentStart == 0 {
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
        log("Panadapter: missing frame(s), expected = \(_expectedFrameNumber), received = \(_frames[_index].frameNumber), acccumulatedBins = \(_accumulatedBins), frameBinCount = \(_frames[_index].frameSize)", .debug, #function, #file, #line)
        _expectedFrameNumber = -1
        _accumulatedBins = 0
        
//        Task { await MainActor.run { streamStatus[id: vita.classCode]?.errors += 1 }}
        
        return
      }
      
      
      
//      print(_frames[_index].number, _frames[_index].segmentStart, _frames[_index].segmentSize, _frames[_index].size)

      
      
      
      vita.payloadData.withUnsafeBytes { ptr in
        // Swap the byte ordering of the data & place it in the bins
        for i in 0..<_frames[_index].segmentSize {
          _frames[_index].intensities[i+_frames[_index].segmentStart] = CFSwapInt16BigToHost( ptr.load(fromByteOffset: byteOffsetToBins + (2 * i), as: UInt16.self) )
        }
      }
      _accumulatedBins += _frames[_index].segmentSize

      
      // is it a complete Frame?
      if _accumulatedBins == _frames[_index].frameSize {
//        // YES, pass it to the delegate
//        delegate?.streamHandler(_frames[_index])

//        print("bin[500] = \(_frames[_index].bins[500])")
        
        
        // YES, post it
        Task { [frame = _frames[_index]] in await MainActor.run {  panadapterFrame = frame }}
        
        // update the expected frame number & dataframe index
        _expectedFrameNumber += 1
        _accumulatedBins = 0
        _index = (_index + 1) % Panadapter.kNumberOfFrames
      }
    }
  }

  
  
  
  
  
  
  public func setProperty(_ property: Property, _ value: String) {
    var adjustedValue = value
    
//    if property == .rxAnt { adjustedValue = apiModel.stdAntennaName(value) }

    switch property {
    case .band:
      if value == "WWV" { adjustedValue = "33"}
      if value == "GEN" { adjustedValue = "34"}
    default:
      break
    }
    
    parse([(property.rawValue, adjustedValue)])
    send(property, adjustedValue)
  }
  
  public enum ZoomType {
    case band
    case minus
    case plus
    case segment
  }
  
  public func setZoom(_ type: ZoomType) {
    
    switch type {
    case .band:
      print("zoom to band")
      
    case .minus:
      if bandwidth * 2 > maxBw {
        // TOO Wide, make the bandwidth maximum value
        setProperty(.bandwidth, maxBw.hzToMhz)
        
      } else {
        // OK, make the bandwidth twice its current value
        setProperty(.bandwidth, (bandwidth * 2).hzToMhz)
      }
    
    case .plus:
      if bandwidth / 2 < minBw {
        // TOO Narrow, make the bandwidth minimum value
        setProperty(.bandwidth, minBw.hzToMhz)
        
      } else {
        // OK, make the bandwidth half its current value
        setProperty(.bandwidth, (bandwidth / 2).hzToMhz)
      }
      
    case .segment:
      print("zoom to segmeny")
    }
  }
  
  public func setIsStreaming(_ value: Bool = true) {
    isStreaming = value
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Send methods
  
  private func send(_ property: Property, _ value: String) {
    _apiModel.sendCommand("display pan set \(id.hex) \(property.rawValue)=\(value)")
  }
  
  /* ----- from FlexApi -----
   "display pan set 0x" + _streamID.ToString("X") + " wnb=" + Convert.ToByte(value)
   "display pan set 0x" + _streamID.ToString("X") + " wnb_level=" + _wnb_level
   "display pan set 0x" + _streamID.ToString("X") + " rxant=" + _rxant
   "display pan set 0x" + _streamID.ToString("X") + " rfgain=" + _rfGain
   "display pan set 0x" + _streamID.ToString("X") + " daxiq_channel=" + _daxIQChannel
   "display pan set 0x" + _streamID.ToString("X") + " xpixels=" + _width
   "display pan set 0x" + _streamID.ToString("X") + " ypixels=" + _height
   "display pan set 0x" + _streamID.ToString("X") + " band=" + _band
   "display pan set 0x" + _streamID.ToString("X") + " fps=" + value
   "display pan set 0x" + _streamID.ToString("X") + " average=" + value
   "display pan set 0x" + _streamID.ToString("x") + " weighted_average=" + Convert.ToByte(_weightedAverage)
   "display pan set 0x" + _streamID.ToString("x") + " n1mm_spectrum_enable=" + Convert.ToByte(_loggerDisplayEnabled)
   "display pan set 0x" + _streamID.ToString("x") + " n1mm_address=" + _loggerDisplayIPAddress.ToString()
   "display pan set 0x" + _streamID.ToString("x") + " n1mm_port=" + _loggerDisplayPort
   "display pan set 0x" + _streamID.ToString("x") + " n1mm_radio=" + _loggerDisplayRadioNum
   "display pan set 0x" + _streamID.ToString("X") + " loopa=" + Convert.ToByte(_loopA)
   "display pan set 0x" + _streamID.ToString("X") + " loopb=" + Convert.ToByte(_loopB)
   */
  
  /// Process the Reply to an Rf Gain Info command, reply format: <value>,<value>,...<value>
  /// - Parameters:
  ///   - seqNum:         the Sequence Number of the original command
  ///   - responseValue:  the response value
  ///   - reply:          the reply
  public func rfGainReplyHandler(_ command: String, sequenceNumber: UInt, responseValue: String, reply: String) {
    // Anything other than 0 is an error
    guard responseValue == kNoError else {
      // log it and ignore the Reply
//      log("Panadapter, non-zero reply: \(command), \(responseValue), \(flexErrorString(errorCode: responseValue))", .warning, #function, #file, #line)
      return
    }
    // parse out the values
    let rfGainInfo = reply.valuesArray( delimiter: "," )
    rfGainLow = rfGainInfo[0].iValue
    rfGainHigh = rfGainInfo[1].iValue
    rfGainStep = rfGainInfo[2].iValue
  }
  
  public func setFillLevel(_ level: Int) {
    fillLevel = level
  }

  
  // FIXME: remove when Panadapter draw logic is updated
  
  
  func updateFreqLegends(_ center: Int, _ bandWidth: Int, _ step: Int) {
    let halfBandWidth = CGFloat(bandWidth)/2
    let low = CGFloat(center) - halfBandWidth
    let high = CGFloat(center) + halfBandWidth
    var legends = [Legend]()
    var offset: CGFloat = 0

    var value = (low + CGFloat(step)) - (low + CGFloat(step)).truncatingRemainder(dividingBy: CGFloat(step))
    var i = 0
    repeat {
      legends.append( Legend(id: i, value: String(format: "%2.3f", value/1_000_000)))
      value = value + CGFloat(step)
      i += 1
    } while value <= high

    offset = -1 + ((low + CGFloat(step)).truncatingRemainder(dividingBy: CGFloat(step))) / CGFloat(step)

    freqLegends = legends
    freqOffset = offset
  }
}

public struct Legend: Identifiable {
  public var id: Int
  public var value: String
}

