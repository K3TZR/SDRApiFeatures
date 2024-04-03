//
//  WaterfallRenderer.swift
//  Waterfall
//
//  Created by Douglas Adams on 10/7/17.
//  Copyright © 2017 Douglas Adams. All rights reserved.
//

import Foundation
import MetalKit
import SwiftUI

import FlexApi
import SharedModel

@MainActor
public final class WaterfallRenderer: NSObject {
  
  //  Vertices    v1  (-1, 1)     |     ( 1, 1)  v3       Texture     v1  ( 0, 0) |---------  ( 1, 0)  v3
  //  (-1 to +1)                  |                       (0 to 1)                |
  //                          ----|----                                           |
  //                              |                                               |
  //              v0  (-1,-1)     |     ( 1,-1)  v2                   v0  ( 0, 1) |           ( 1, 1)  v2
  //
  
  // ----------------------------------------------------------------------------
  // MARK: - Shader structs

  struct Intensity {
    var i: UInt16 = 0
  }
  
  struct Line {
    var index: UInt16 = 0
  }
  
  struct BinData {
    var firstBinFrequency: Float = 0.0
    var binBandwidth: Float = 0.0
  }
  
  struct Constants {
    var blackLevel: UInt16 = 0
    var colorGain: UInt16 = 0
    var numberOfBufferLines: UInt16 = 0
    var numberOfScreenLines: UInt16 = 0
    var startingFrequency: Float = 0.0
    var endingFrequency: Float = 0.0
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private static let kBufferLines = 2048        // must be >= max number of lines
  private static let kGradientSize = 256
  
  private var _binData = BinData()
  private var _binDataBuffer: MTLBuffer!
  private var _commandQueue: MTLCommandQueue!
  private var _constants = Constants()
  private var _device: MTLDevice!
  private var _gradientSamplerState: MTLSamplerState!
  private var _gradientTexture: MTLTexture!
  private var _intensityBuffer: MTLBuffer!
  private var _line = Line()
  private var _lineIndexBuffer: MTLBuffer!
  private var _panadapter: Panadapter!
  private var _pipelineState: MTLRenderPipelineState!
  private var _previousFrameNumber = 0
  private var _waterfall: Waterfall!
  private var _writeTo = 0
 
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(_ panadapter: Panadapter, _ waterfall: Waterfall) {
    _panadapter = panadapter
    _waterfall = waterfall
    
    super.init()
    
    // Setup persistent objects & state
    _device = MTLCreateSystemDefaultDevice()
    makeIntensityBuffer(device: _device)
    makeBinDataBuffer(device: _device)
    makeLineIndexBuffer(device: _device)
    makePipelineState(device: _device)
    makeGradientTexture(device: _device)
    makeGradientSampler(device: _device)
    makeCommandQueue(device: _device)
    setGradient(loadGradient(index: _waterfall.gradientIndex) )
  }
    
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  private func setConstants(_ size: CGSize, autoBlackLevel: UInt32) {
    _constants.blackLevel = _waterfall.autoBlackEnabled ? UInt16(autoBlackLevel) : UInt16( (Float(_waterfall.blackLevel) / 500.0) * Float(UInt16.max) )
    _constants.colorGain = UInt16(_waterfall.colorGain)
    _constants.endingFrequency = Float(_panadapter.center + _panadapter.bandwidth/2)
    _constants.numberOfBufferLines = UInt16(WaterfallRenderer.kBufferLines)
    _constants.numberOfScreenLines = UInt16(size.height)
    _constants.startingFrequency = Float(_panadapter.center - _panadapter.bandwidth/2)
  }

  private func makeIntensityBuffer(device: MTLDevice) {
    // create the buffer at it's maximum size
    let size = WaterfallRenderer.kBufferLines * WaterfallFrame.kMaxBins * MemoryLayout<Intensity>.stride
    _intensityBuffer = device.makeBuffer(length: size, options: [.storageModeShared])
  }
  
  private func makeBinDataBuffer(device: MTLDevice) {
    // create the buffer at it's maximum size
    let size = WaterfallRenderer.kBufferLines * MemoryLayout<BinData>.stride
    _binDataBuffer = device.makeBuffer(length: size, options: [.storageModeShared])
  }
  
  private func makeLineIndexBuffer(device: MTLDevice) {
    // create the buffer at it's maximum size
    let size = WaterfallRenderer.kBufferLines * MemoryLayout<Line>.stride
    _lineIndexBuffer = device.makeBuffer(length: size, options: [.storageModeShared])
    
    // number each entry with its index value
    for i in 0..<WaterfallRenderer.kBufferLines {
      _line.index = UInt16(i)
      memcpy(_lineIndexBuffer.contents().advanced(by: i * MemoryLayout<Line>.stride), &_line, MemoryLayout<Line>.size)
    }
  }
  
  private func makePipelineState(device: MTLDevice) {
    // get the Library (contains all compiled .metal files in this project)
    let library = try! device.makeDefaultLibrary(bundle: Bundle.module)
    
    // create the Render Pipeline Descriptor
    let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
    renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "waterfall_vertex")
    renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "waterfall_fragment")
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    do {
      _pipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    } catch {
      fatalError("WaterfallRenderer: failed to create render pipeline state")
    }
  }
  
  private func makeGradientTexture(device: MTLDevice) {
    // define a 1D texture for a Gradient
    let textureDescriptor = MTLTextureDescriptor()
    textureDescriptor.textureType = .type1D
    textureDescriptor.pixelFormat = .bgra8Unorm
    textureDescriptor.width = WaterfallRenderer.kGradientSize
    textureDescriptor.usage = [.shaderRead]
    _gradientTexture = device.makeTexture(descriptor: textureDescriptor)
  }
  
  private func makeGradientSampler(device: MTLDevice) {
    // create a gradient Sampler state
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.sAddressMode = .clampToEdge
    samplerDescriptor.tAddressMode = .clampToEdge
    samplerDescriptor.minFilter = .nearest
    samplerDescriptor.magFilter = .nearest
    _gradientSamplerState = device.makeSamplerState(descriptor: samplerDescriptor)
  }
  
  private func makeCommandQueue(device: MTLDevice) {
    // create a Command Queue object
    _commandQueue = device.makeCommandQueue()
  }
  
  private func setGradient(_ array: [UInt8]) {
    // copy the Gradient data into the texture
    let region = MTLRegionMake1D(0, WaterfallRenderer.kGradientSize)
    _gradientTexture!.replace(region: region, mipmapLevel: 0, withBytes: array, bytesPerRow: WaterfallRenderer.kGradientSize * MemoryLayout<Float>.size)
  }
  
  /// Load the gradient at the specified index
  ///
  private func loadGradient(index: Int) -> [UInt8] {
    var i = 0
    if (0..<Waterfall.gradients.count).contains(index) { i = index }
      
    return loadGradientFile(name: Waterfall.gradients[i])
  }

  /// Load a gradient from the named file
  ///
  private func loadGradientFile(name: String) -> [UInt8] {
      var file: FileHandle?
      
      if let texURL = Bundle.module.url(forResource: name, withExtension: "tex") {
          do {
              file = try FileHandle(forReadingFrom: texURL)
          } catch {
              fatalError("Gradient file '\(name).tex' not found")
          }
          // Read all the data
          let data = file!.readDataToEndOfFile()
          
          // Close the file
          file!.closeFile()
          
          // copy the data into the gradientArray
          var array = [UInt8](repeating: 0, count: data.count)
          data.copyBytes(to: &array[0], count: data.count)
          
          return array
      }
      // resource not found
      fatalError("Gradient file '\(name).tex' not found")
  }
}

// ----------------------------------------------------------------------------
// MARK: - MTKViewDelegate protocol methods

extension WaterfallRenderer: MTKViewDelegate {
  
  /// The size of the MetalKit View has changed
  ///
  /// - Parameters:
  ///   - view:         the MetalKit View
  ///   - size:         its new size
  ///
  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    DispatchQueue.main.async { [unowned self] in
      self._constants.numberOfScreenLines = UInt16(size.height)
    }
  }
  /// Draw lines colored by the Gradient texture
  ///
  /// - Parameter view: the MetalKit view
  ///
  public func draw(in view: MTKView) {
    
    if var frame = _waterfall.waterfallFrame {
      
      if frame.frameNumber > _previousFrameNumber {
        _previousFrameNumber = frame.frameNumber
        
        // copy the Intensities into the Intensity buffer
        memcpy(_intensityBuffer.contents().advanced(by: _writeTo * MemoryLayout<Intensity>.stride * WaterfallFrame.kMaxBins),
               &frame.bins, frame.frameBinCount * MemoryLayout<UInt16>.size)
        
        // update the constants
        setConstants(view.frame.size, autoBlackLevel: frame.autoBlackLevel)
        
        // copy the First Bin Frequency & Bin Bandwidth for this line
        var firstBinFrequency = Float(frame.firstBinFreq)
        var binBandwidth = Float(frame.binBandwidth)
 
        memcpy(_binDataBuffer.contents().advanced(by: _writeTo * MemoryLayout<BinData>.stride), &firstBinFrequency, MemoryLayout<Float>.size)
        memcpy(_binDataBuffer.contents().advanced(by: _writeTo * MemoryLayout<BinData>.stride + MemoryLayout<Float>.stride), &binBandwidth, MemoryLayout<Float>.size)
        
        // obtain a Command buffer, Render Pass descriptor, Render Command Encoder
        guard let commandBuffer = _commandQueue.makeCommandBuffer() else { fatalError("Unable to create a Command Buffer") }
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { fatalError("Unable to create a Render Pass Descriptor") }
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { fatalError("Unable to create a Render Command Encoder") }
        
        // set Load action & clear color
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
        
        renderCommandEncoder.pushDebugGroup("Draw")
        
        // set the pipeline state
        renderCommandEncoder.setRenderPipelineState(_pipelineState)
        
        // bind the buffers
        renderCommandEncoder.setVertexBuffer(_intensityBuffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBuffer(_binDataBuffer, offset: 0, index: 1)
        renderCommandEncoder.setVertexBuffer(_lineIndexBuffer, offset: 0, index: 2)
        renderCommandEncoder.setVertexBytes(&_constants, length: MemoryLayout<Constants>.size, index: 3)
        
        // bind the Gradient texture & sampler
        renderCommandEncoder.setFragmentTexture(_gradientTexture, index: 0)
        renderCommandEncoder.setFragmentSamplerState(_gradientSamplerState, index: 0)
                
        // Draw as many lines as fit on the screen
        var offset = _writeTo
        for i in 0...Int(_constants.numberOfScreenLines) {
          
          // set the buffer offsets
          renderCommandEncoder.setVertexBufferOffset(offset * MemoryLayout<Intensity>.stride * WaterfallFrame.kMaxBins, index: 0)
          renderCommandEncoder.setVertexBufferOffset((offset * MemoryLayout<BinData>.stride), index: 1)
          renderCommandEncoder.setVertexBufferOffset(i * MemoryLayout<Line>.stride, index: 2)
          // add the line to the drawing
          renderCommandEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: WaterfallFrame.kMaxBins)
          
          if offset - 1 < 0 {
            offset = Int(_constants.numberOfBufferLines) - 1
          } else {
            offset -= 1
          }
        }
        
        // finish encoding commands
        renderCommandEncoder.endEncoding()
        
        // present the drawable to the screen
        commandBuffer.present(view.currentDrawable!)
        
        // finalize rendering & push the command buffer to the GPU
        commandBuffer.commit()
        
        _writeTo = (_writeTo + 1) % WaterfallRenderer.kBufferLines
      }
    }
  }
}
