//
//  PanadapterStream.swift
//  FlexApiFeature/Streams
//
//  Created by Douglas Adams on 4/20/24.
//  Copyright © 2017 Douglas Adams & Mario Illgen. All rights reserved.
//

import Foundation

import SharedFeature
import VitaFeature
import XCGLogFeature

// PanadapterStream Class implementation
//      PanadapterStream instances process FFT data used to display a panadapter.
//      They are added / removed by the incoming TCP messages.
//      They are collected in the StreamModel.PanadapterStreams collection.
@Observable
public final class PanadapterStream: Identifiable, StreamProcessor {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(_ id: UInt32) {
    self.id = id
    log("PanadapterStream \(id.hex) ADDED", .debug, #function, #file, #line)
  }
  
  // ------------------------------------------------------------------------------
  // MARK: - Public properties
  
  public let id: UInt32
  public var panadapterFrame = [UInt16](repeating: 0, count: 5120)
  
  // ------------------------------------------------------------------------------
  // MARK: - Private properties
  
//  private struct PayloadHeader {      // struct to mimic payload layout
//    var startingBinNumber: UInt16
//    var segmentBinCount: UInt16
//    var binSize: UInt16
//    var frameBinCount: UInt16
//    var frameNumber: UInt32
//  }
//  
//  private var _accumulatedBins = 0
//  private var _droppedPackets = 0
//  private var _expectedFrameNumber = -1
//  private var _frames = [PanadapterFrame](repeating: PanadapterFrame(), count: kNumberOfFrames)
//  private var _index: Int = 0
  
    private var _frame = PanadapterFrame()
  
  // ----------------------------------------------------------------------------
  // MARK: - Private Static properties
  
  private static let kNumberOfFrames = 16
  private static let dbmMax: CGFloat = 20
  private static let dbmMin: CGFloat = -180

  // ----------------------------------------------------------------------------
  // MARK: - Public methods

  /// Process the Panadapter Vita struct
  ///      The payload of the incoming Vita struct is converted to a PanadapterFrame and
  ///      passed to the Panadapter Stream Handler
  ///
  /// - Parameters:
  ///   - vita:        a Vita struct
  public func streamProcessor(_ vita: Vita) {

    Task {
      if await _frame.process(vita) {
        panadapterFrame = await _frame.getFrame()
//        print("frame Complete")
      }
    }

      //    // Bins are just beyond the payload
//    let byteOffsetToBins = MemoryLayout<PayloadHeader>.size
//    
//    vita.payloadData.withUnsafeBytes { ptr in
//      // map the payload to the Payload struct
//      let hdr = ptr.bindMemory(to: PayloadHeader.self)
//
//      _frames[_index].segmentStart = Int(CFSwapInt16BigToHost(hdr[0].startingBinNumber))
//      _frames[_index].segmentSize = Int(CFSwapInt16BigToHost(hdr[0].segmentBinCount))
//      _frames[_index].binSize = Int(CFSwapInt16BigToHost(hdr[0].binSize))
//      _frames[_index].frameSize = Int(CFSwapInt16BigToHost(hdr[0].frameBinCount))
//      _frames[_index].frameNumber = Int(CFSwapInt32BigToHost(hdr[0].frameNumber))
//
//      // validate the packet (could be incomplete at startup)
//      if _frames[_index].frameSize == 0 { return }
//      if _frames[_index].segmentStart + _frames[_index].segmentSize > _frames[_index].frameSize { return }
//      
//      // are we waiting for the start of a frame?
//      if _expectedFrameNumber == -1 {
//        // YES, is it the start of a frame?
//        if _frames[_index].segmentStart == 0 {
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
//        log("Panadapter: missing frame(s), expected = \(_expectedFrameNumber), received = \(_frames[_index].frameNumber), acccumulatedBins = \(_accumulatedBins), frameBinCount = \(_frames[_index].frameSize)", .debug, #function, #file, #line)
//        _expectedFrameNumber = -1
//        _accumulatedBins = 0
//        return
//      }
//      
//      vita.payloadData.withUnsafeBytes { ptr in
//        // Swap the byte ordering of the data & place it in the bins
//        for i in 0..<_frames[_index].segmentSize {
//          _frames[_index].intensities[i+_frames[_index].segmentStart] = CFSwapInt16BigToHost( ptr.load(fromByteOffset: byteOffsetToBins + (2 * i), as: UInt16.self) )
//        }
//      }
//      _accumulatedBins += _frames[_index].segmentSize
//
//      
//      // is it a complete Frame?
//      if _accumulatedBins == _frames[_index].frameSize {
//        // YES, post it
//        panadapterFrame = _frames[_index]
//        
//        // update the expected frame number & dataframe index
//        _expectedFrameNumber += 1
//        _accumulatedBins = 0
//        _index = (_index + 1) % PanadapterStream.kNumberOfFrames
//      }
//    }
  }
}
