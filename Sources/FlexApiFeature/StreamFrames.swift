//
//  StreamFrames.swift
//
//
//  Created by Douglas Adams on 4/24/23.
//

import Foundation
import Accelerate
import AVFoundation

import VitaFeature


/// Struct containing Dax IQ Stream data
public struct DaxIqStreamFrame {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var daxIqChannel                   = -1
  public private(set) var numberOfSamples   = 0
  public var realSamples                    = [Float]()
  public var imagSamples                    = [Float]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _kOneOverZeroDBfs  : Float = 1.0 / pow(2.0, 15.0)
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize an IqStreamFrame
  /// - Parameters:
  ///   - payload:        pointer to a Vita packet payload
  ///   - numberOfBytes:  number of bytes in the payload
  public init(payload: [UInt8], numberOfBytes: Int, daxIqChannel: Int) {
    // 4 byte each for left and right sample (4 * 2)
    numberOfSamples = numberOfBytes / (4 * 2)
    self.daxIqChannel = daxIqChannel
    
    // allocate the samples arrays
    realSamples = [Float](repeating: 0, count: numberOfSamples)
    imagSamples = [Float](repeating: 0, count: numberOfSamples)
    
    payload.withUnsafeBytes { (payloadPtr) in
      // get a pointer to the data in the payload
      let wordsPtr = payloadPtr.bindMemory(to: Float32.self)
      
      // allocate temporary data arrays
      var dataLeft = [Float32](repeating: 0, count: numberOfSamples)
      var dataRight = [Float32](repeating: 0, count: numberOfSamples)
      
      // FIXME: is there a better way
      // de-interleave the data
      for i in 0..<numberOfSamples {
        dataLeft[i] = wordsPtr[2*i]
        dataRight[i] = wordsPtr[(2*i) + 1]
      }
      // copy & normalize the data
      vDSP_vsmul(&dataLeft, 1, &_kOneOverZeroDBfs, &realSamples, 1, vDSP_Length(numberOfSamples))
      vDSP_vsmul(&dataRight, 1, &_kOneOverZeroDBfs, &imagSamples, 1, vDSP_Length(numberOfSamples))
    }
  }
}

/// Struct containing RemoteRxAudio (Opus) Stream data
//public struct RemoteRxAudioFrame {
//
//  // ----------------------------------------------------------------------------
//  // MARK: - Public properties
//
//  public var samples: [UInt8]                     // array of UInt8 samples
//  public var numberOfSamples: Int                 // number of UInt8's (i.e.bytes)
//  public var isCompressed: Bool
//
//  // ----------------------------------------------------------------------------
//  // MARK: - Initialization
//
//  /// Initialize a RemoteRxAudioFrame
//  /// - Parameters:
//  ///   - payload:            pointer to the Vita packet payload
//  ///   - numberOfSamples:    number of Samples in the payload
//  public init(payload: [UInt8], numberOfSamples: Int, isCompressed: Bool) {
//    // allocate the samples array
//    samples = [UInt8](repeating: 0, count: numberOfSamples)
//
//    // save the count and copy the data
//    self.numberOfSamples = numberOfSamples
//    memcpy(&samples, payload, numberOfSamples)
//    self.isCompressed = isCompressed
//  }
//}

/// Struct containing DaxRxAudioStream data
public struct DaxRxAudioFrame {
  /*
   The payload consists of 'numberOfSamples' audio frames
   
      a frame consists of two Float32 values:   |  Float32 | Float32 |
                                                |  Left    | Right   |
   */
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var numberOfFrames: Int          // number of Audio frames
  public var daxChannel: Int
//  public var leftAudio: [Float]
//  public var rightAudio: [Float]
  public var pcmBuffer: AVAudioPCMBuffer

  
  private static let sampleRate: Double = 24_000
  private static let channelCount = 2
  private static let elementSize = MemoryLayout<Float>.size
  // interleaved, BigEndian, Float32 pcm data
  private static var pcmASBD = AudioStreamBasicDescription(mSampleRate: sampleRate,
                                                           mFormatID: kAudioFormatLinearPCM,
                                                           mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsBigEndian,
                                                           mBytesPerPacket: UInt32(elementSize * 2),
                                                           mFramesPerPacket: 1,
                                                           mBytesPerFrame: UInt32(elementSize * 2),
                                                           mChannelsPerFrame: UInt32(channelCount),
                                                           mBitsPerChannel: UInt32(elementSize * 8) ,
                                                           mReserved: 0)

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a DaxRxAudioFrame
  /// - Parameters:
  ///   - payload:            array of bytes from the Vita packet payload
  ///   - numberOfSamples:    number of Audio Frames in the payload array
  public init(payload: [UInt8], numberOfFrames: Int, daxChannel: Int = -1) {
    self.numberOfFrames = numberOfFrames // number of Audio frames
    self.daxChannel = daxChannel
    
    // create the AVAudioPCMBuffer
    pcmBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(streamDescription: &DaxRxAudioFrame.pcmASBD)!, frameCapacity: UInt32(numberOfFrames))!
    pcmBuffer.frameLength = pcmBuffer.frameCapacity

    // copy the incoming data to the AVAudioPCMBuffer
    let numberOfBytes = numberOfFrames * DaxRxAudioFrame.channelCount * DaxRxAudioFrame.elementSize
    memcpy(pcmBuffer.floatChannelData![0], payload, numberOfBytes)
  }
}

    // allocate the array properties
//    self.leftAudio = [Float](repeating: 0, count: numberOfSamples)
//    self.rightAudio = [Float](repeating: 0, count: numberOfSamples)
//    var swappedAudio = [UInt32](repeating: 0, count: numberOfFrames * 2)

//    payload.withUnsafeBytes { (payloadPtr) in
      // get a pointer to the 32-bit Float stereo samples
//      let uint32Ptr = payloadPtr.bindMemory(to: UInt32.self)
      
      // Swap the byte ordering of the interleaved samples
//      for i in 0..<numberOfFrames * 2 {
//        swappedAudio[i] = CFSwapInt32BigToHost(uint32Ptr[i])
//      }

//      memcpy(pcmBuffer.floatChannelData![0], &swappedAudio, numberOfFrames * DaxRxAudioFrame.channelCount * DaxRxAudioFrame.elementSize)
      // allocate temporary data arrays
//      var dataLeft = [UInt32](repeating: 0, count: numberOfSamples)
//      var dataRight = [UInt32](repeating: 0, count: numberOfSamples)
//
//      // Swap the byte ordering of the interleaved samples
//      for i in 0..<numberOfSamples {
//        dataLeft[i] = CFSwapInt32BigToHost(uint32Ptr[2*i])
//        dataRight[i] = CFSwapInt32BigToHost(uint32Ptr[(2*i) + 1])
//      }
//
//      // copy the byte-swapped Float32 data
//      let numberOfBytes = numberOfSamples * MemoryLayout<Float>.size
//      memcpy(&leftAudio, &dataLeft, numberOfBytes)
//      memcpy(&rightAudio, &dataRight, numberOfBytes)
//    }

/// Struct containing DaxRxAudioStream data (reduced BW)
public struct DaxRxReducedAudioFrame {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  public var numberOfSamples  : Int
  public var daxChannel       : Int
  public var leftAudio        = [Float]()
  public var rightAudio       = [Float]()
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  /// Initialize a DaxRxReducedAudioFrame
  /// - Parameters:
  ///   - payload:            pointer to the Vita packet payload
  ///   - numberOfSamples:    number of Samples in the payload
  public init(payload: [UInt8], numberOfSamples: Int, daxChannel: Int = -1) {
    let oneOverMax: Float = 1.0 / Float(Int16.max)
    
    self.numberOfSamples = numberOfSamples
    self.daxChannel = daxChannel
    
    // allocate the samples arrays
    self.leftAudio = [Float](repeating: 0, count: numberOfSamples)
    self.rightAudio = [Float](repeating: 0, count: numberOfSamples)
    
    payload.withUnsafeBytes { (payloadPtr) in
      // Int16 Mono Samples
      // get a pointer to the data in the payload
      let int16Ptr = payloadPtr.bindMemory(to: Int16.self)
      
      // allocate temporary data arrays
      var dataLeft = [Float](repeating: 0, count: numberOfSamples)
      var dataRight = [Float](repeating: 0, count: numberOfSamples)
      
      // Swap the byte ordering of the samples & place it in the dataFrame left and right samples
      for i in 0..<numberOfSamples {
        let uIntVal = CFSwapInt16BigToHost(UInt16(bitPattern: int16Ptr[i]))
        let intVal = Int16(bitPattern: uIntVal)
        // convert to Float
        let floatVal = Float(intVal) * oneOverMax
        
        dataLeft[i] = floatVal
        dataRight[i] = floatVal
      }
      // copy the data as is -- it is already floating point
      memcpy(&leftAudio, &dataLeft, numberOfSamples * 4)
      memcpy(&rightAudio, &dataRight, numberOfSamples * 4)
    }
  }
}


/// Struct containing Panadapter Stream data
public actor PanadapterFrame: Sendable {
  private static let kMaxBins = 5120
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var isComplete = false
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties

  private struct PayloadHeader {      // struct to mimic payload layout
    var startingBinNumber: UInt16
    var segmentBinCount: UInt16
    var binSize: UInt16
    var frameBinCount: UInt16
    var frameNumber: UInt32
  }

  private var _panadapterFrame = [UInt16](repeating: 0, count: kMaxBins)

  private var _accumulatedBins = 0
  private var _binSize = 2                                            // Bin size in bytes
  private var _expectedFrameNumber = -1
  private var _frame = [UInt16](repeating: 0, count: kMaxBins)        // Array of intensity values
  private var _frameNumber = 0                                        // Frame number
  private var _frameSize = 0                                          // number of bins in the complete frame
  private var _segmentSize = 0                                        // number of bins in this segment
  private var _segmentStart = 0                                       // first bin in this segment

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func getFrame() -> [UInt16] {
    return _panadapterFrame
  }
  
  public func process(_ vita: Vita) -> Bool {
    isComplete = false
    
    // Bins are just beyond the payload
    let byteOffsetToBins = MemoryLayout<PayloadHeader>.size
    
    vita.payloadData.withUnsafeBytes { ptr in
      // map the payload to the Payload struct
      let hdr = ptr.bindMemory(to: PayloadHeader.self)
      
      _segmentStart = Int(CFSwapInt16BigToHost(hdr[0].startingBinNumber))
      _segmentSize = Int(CFSwapInt16BigToHost(hdr[0].segmentBinCount))
      _binSize = Int(CFSwapInt16BigToHost(hdr[0].binSize))
      _frameSize = Int(CFSwapInt16BigToHost(hdr[0].frameBinCount))
      _frameNumber = Int(CFSwapInt32BigToHost(hdr[0].frameNumber))
      
      // validate the packet (could be incomplete at startup)
      if _frameSize == 0 { return }
      if _segmentStart + _segmentSize > _frameSize { return }
      
      // are we waiting for the start of a frame?
      if _expectedFrameNumber == -1 {
        // YES, is it the start of a frame?
        if _segmentStart == 0 {
          // YES, START OF A FRAME
          _expectedFrameNumber = _frameNumber
        } else {
          // NO, NOT THE START OF A FRAME
          return
        }
      }
      // is it the expected frame?
      if _expectedFrameNumber != _frameNumber {
        // NOT THE EXPECTED FRAME, wait for the next start of frame
//        log("Panadapter: missing frame(s), expected = \(_expectedFrameNumber), received = \(frameNumber), acccumulatedBins = \(_accumulatedBins), frameBinCount = \(frameSize)", .debug, #function, #file, #line)
        _expectedFrameNumber = -1
        _accumulatedBins = 0
        return
      }
      
      vita.payloadData.withUnsafeBytes { ptr in
        // Swap the byte ordering of the data & place it in the bins
        for i in 0..<_segmentSize {
          _frame[i+_segmentStart] = CFSwapInt16BigToHost( ptr.load(fromByteOffset: byteOffsetToBins + (2 * i), as: UInt16.self) )
        }
      }
      _accumulatedBins += _segmentSize
      
    }
    // is it a complete Frame?
    if _accumulatedBins == _frameSize {
      isComplete = true
      // update the expected frame number & dataframe index
      _expectedFrameNumber += 1
      _accumulatedBins = 0
      
      // Complete frame
      _panadapterFrame = _frame
    }
    return isComplete
  }
}

/// Struct containing Waterfall Stream data
public actor WaterfallFrame {
  public static let kMaxBins = 4096

  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var waterfallFrame = [UInt16](repeating: 0, count: kMaxBins)

  public var firstBinFreq: CGFloat = 0.0  // Frequency of first Bin (Hz)
  public var binBandwidth: CGFloat = 0.0  // Bandwidth of a single bin (Hz)
  public var lineDuration  = 0            // Duration of this line (ms)
  //  public var segmentBinCount = 0          // Number of bins
  public var height = 0                   // Height of frame (pixels)
  public var frameNumber = 0              // Time code
  public var autoBlackLevel: UInt32 = 0   // Auto black level
  public var frameBinCount = 0            //
  //  public var startingBinNumber = 0        //
  public var bins = [UInt16](repeating: 0, count: kMaxBins)            // Array of bin values
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
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
  private var _frame = [UInt16](repeating: 0, count: kNumberOfFrames )
  private var _segmentBinCount = 0
  private var _startingBinNumber = 0

  private static let kNumberOfFrames = 10

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func process(_ vita: Vita) {
    // Bins are just beyond the payload
    let byteOffsetToBins = MemoryLayout<PayloadHeader>.size
    
    vita.payloadData.withUnsafeBytes { ptr in
      // map the payload to the Payload struct
      let hdr = ptr.bindMemory(to: PayloadHeader.self)
      
      // validate the packet (could be incomplete at startup)
      _startingBinNumber = Int(CFSwapInt16BigToHost(hdr[0].startingBinNumber))
      _segmentBinCount = Int(CFSwapInt16BigToHost(hdr[0].segmentBinCount))
      frameBinCount = Int(CFSwapInt16BigToHost(hdr[0].frameBinCount))
      frameNumber = Int(CFSwapInt32BigToHost(hdr[0].frameNumber))
      
      if frameBinCount == 0 { return }
      if _startingBinNumber + _segmentBinCount > frameBinCount { return }
      
      // populate frame values
      firstBinFreq = CGFloat(CFSwapInt64BigToHost(hdr[0].firstBinFreq)) / 1.048576E6
      binBandwidth = CGFloat(CFSwapInt64BigToHost(hdr[0].binBandwidth)) / 1.048576E6
      lineDuration = Int( CFSwapInt32BigToHost(hdr[0].lineDuration) )
      height = Int( CFSwapInt16BigToHost(hdr[0].height) )
      autoBlackLevel = CFSwapInt32BigToHost(hdr[0].autoBlackLevel)
      
      // are we waiting for the start of a frame?
      if _expectedFrameNumber == -1 {
        // YES, is it the start of a frame?
        if _startingBinNumber == 0 {
          // YES, START OF A FRAME
          _expectedFrameNumber = frameNumber
        } else {
          // NO, NOT THE START OF A FRAME
          return
        }
      }
      // is it the expected frame?
      if _expectedFrameNumber != frameNumber {
        // NOT THE EXPECTED FRAME, wait for the next start of frame
//        log("Waterfall: missing frame(s), expected = \(_expectedFrameNumber), received = \(frameNumber), accumulatedBins = \(_accumulatedBins), frameBinCount = \(frameBinCount)", .debug, #function, #file, #line)
        _expectedFrameNumber = -1
        _accumulatedBins = 0
        return
      }
      // copy the data
      vita.payloadData.withUnsafeBytes { ptr in
        // Swap the byte ordering of the data & place it in the bins
        for i in 0..<_segmentBinCount {
          bins[i+_startingBinNumber] = CFSwapInt16BigToHost( ptr.load(fromByteOffset: byteOffsetToBins + (2 * i), as: UInt16.self) )
        }
      }
      _accumulatedBins += _segmentBinCount
      
      // is it a complete Frame?
      if _accumulatedBins == frameBinCount {
        // updated just to be consistent (so that downstream won't use the wrong count)
        
        // YES, post it
        waterfallFrame = _frame
        
        // update the expected frame number & dataframe index
        _expectedFrameNumber += 1
        _accumulatedBins = 0
      }
    }
  }
}

/*
 public var firstBinFreq: CGFloat = 0.0  // Frequency of first Bin (Hz)
 public var binBandwidth: CGFloat = 0.0  // Bandwidth of a single bin (Hz)
 public var lineDuration  = 0            // Duration of this line (ms)
 public var binsInThisFrame = 0          // Number of bins
 public var height = 0                   // Height of frame (pixels)
 public var receivedFrame = 0            // Time code
 public var autoBlackLevel: UInt32 = 0   // Auto black level
 public var totalBins = 0                //
 public var startingBin = 0              //
 public var bins = [UInt16]()            // Array of bin values

 */
