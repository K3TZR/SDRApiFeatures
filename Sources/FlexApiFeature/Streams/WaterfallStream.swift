//
//  WaterfallStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 4/20/24.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import SharedFeature
import VitaFeature


// WaterfallStream Class implementation
//      WaterfallStream instances process FFT data used to display a waterfall.
//      They are added / removed by the incoming TCP messages.
//      They are collected in the StreamModel.WaterfallStreams collection.
@Observable
public final class WaterfallStream: Identifiable, StreamProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) {
    self.id = id
    apiLog.debug("WaterfallStream \(id.hex) ADDED")
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var waterfallFrame: WaterfallFrame?

  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
//  private struct PayloadHeader {    // struct to mimic payload layout
//    var firstBinFreq: UInt64        // 8 bytes
//    var binBandwidth: UInt64        // 8 bytes
//    var lineDuration : UInt32       // 4 bytes
//    var segmentBinCount: UInt16     // 2 bytes
//    var height: UInt16              // 2 bytes
//    var frameNumber: UInt32         // 4 bytes
//    var autoBlackLevel: UInt32      // 4 bytes
//    var frameBinCount: UInt16       // 2 bytes
//    var startingBinNumber: UInt16   // 2 bytes
//  }
//  
//  private var _accumulatedBins = 0
//  private var _expectedFrameNumber = -1
//  private var _frames = [WaterfallFrame](repeating: WaterfallFrame(), count:kNumberOfFrames )
//  private var _index: Int = 0
//  private var _segmentBinCount = 0
//  private var _startingBinNumber = 0
//
//  private static let kNumberOfFrames = 10
  
    private var _frame = WaterfallFrame()
  

// ------------------------------------------------------------------------------
// MARK: - Public methods

  /// Process the Waterfall Vita struct
  ///      The payload of the incoming Vita struct is converted to a WaterfallFrame and
  ///      passed to the Waterfall Stream Handler
  /// - Parameters:
  ///   - vita:       a Vita struct
  public func streamProcessor(_ vita: Vita) {
  }
}

//    Task {
//      if await _frame.process(vita) {
//        waterfallFrame = await _frame.getFrame()
//        print("frame Complete")
//      }
//    }

//    // Bins are just beyond the payload
//    let byteOffsetToBins = MemoryLayout<PayloadHeader>.size
//    
//    vita.payloadData.withUnsafeBytes { ptr in
//      // map the payload to the Payload struct
//      let hdr = ptr.bindMemory(to: PayloadHeader.self)
//      
//      // validate the packet (could be incomplete at startup)
//      _startingBinNumber = Int(CFSwapInt16BigToHost(hdr[0].startingBinNumber))
//      _segmentBinCount = Int(CFSwapInt16BigToHost(hdr[0].segmentBinCount))
//      _frames[_index].frameBinCount = Int(CFSwapInt16BigToHost(hdr[0].frameBinCount))
//      _frames[_index].frameNumber = Int(CFSwapInt32BigToHost(hdr[0].frameNumber))
//      
//      if _frames[_index].frameBinCount == 0 { return }
//      if _startingBinNumber + _segmentBinCount > _frames[_index].frameBinCount { return }
//      
//      // populate frame values
//      _frames[_index].firstBinFreq = CGFloat(CFSwapInt64BigToHost(hdr[0].firstBinFreq)) / 1.048576E6
//      _frames[_index].binBandwidth = CGFloat(CFSwapInt64BigToHost(hdr[0].binBandwidth)) / 1.048576E6
//      _frames[_index].lineDuration = Int( CFSwapInt32BigToHost(hdr[0].lineDuration) )
//      _frames[_index].height = Int( CFSwapInt16BigToHost(hdr[0].height) )
//      _frames[_index].autoBlackLevel = CFSwapInt32BigToHost(hdr[0].autoBlackLevel)
//      
//      // are we waiting for the start of a frame?
//      if _expectedFrameNumber == -1 {
//        // YES, is it the start of a frame?
//        if _startingBinNumber == 0 {
//          // YES, START OF A FRAME
//          _expectedFrameNumber = _frames[_index].frameNumber
//        } else {
//          // NO, NOT THE START OF A FRAME
//          return
//        }
//      }
//      // is it the expected frame?
//      if _expectedFrameNumber != _frames[_index].frameNumber {
//        // NOT THE EXPECTED FRAME, wait for the next start of frame
//        log("Waterfall: missing frame(s), expected = \(_expectedFrameNumber), received = \(_frames[_index].frameNumber), accumulatedBins = \(_accumulatedBins), frameBinCount = \(_frames[_index].frameBinCount)", .debug, #function, #file, #line)
//        _expectedFrameNumber = -1
//        _accumulatedBins = 0
//        return
//      }
//      // copy the data
//      vita.payloadData.withUnsafeBytes { ptr in
//        // Swap the byte ordering of the data & place it in the bins
//        for i in 0..<_segmentBinCount {
//          _frames[_index].bins[i+_startingBinNumber] = CFSwapInt16BigToHost( ptr.load(fromByteOffset: byteOffsetToBins + (2 * i), as: UInt16.self) )
//        }
//      }
//      _accumulatedBins += _segmentBinCount
//
//      // is it a complete Frame?
//      if _accumulatedBins == _frames[_index].frameBinCount {
//        // updated just to be consistent (so that downstream won't use the wrong count)
//
//        // YES, post it
//        waterfallFrame = _frames[_index]
//
//        // update the expected frame number & dataframe index
//        _expectedFrameNumber += 1
//        _accumulatedBins = 0
//        _index = (_index + 1) % WaterfallStream.kNumberOfFrames
//      }
//    }


