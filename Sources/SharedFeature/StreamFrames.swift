//
//  StreamFrames.swift
//  
//
//  Created by Douglas Adams on 4/24/23.
//

import Foundation
import Accelerate
import AVFoundation

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
public struct PanadapterFrame: Sendable {
  private static let kMaxBins = 5120
  
  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties

  public var intensities = [UInt16](repeating: 0, count: kMaxBins)  // Array of intensity values
  public var binSize = 2                                            // Bin size in bytes
  public var frameNumber = 0                                        // Frame number
  public var segmentStart = 0                                       // first bin in this segment
  public var segmentSize = 0                                        // number of bins in this segment
  public var frameSize = 0                                          // number of bins in the complete frame
}

/// Struct containing Waterfall Stream data
public struct WaterfallFrame {
  public static let kMaxBins = 4096

  public init() {}
  
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
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
