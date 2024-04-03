//
//  WaterfallView.swift
//
//  Created by Douglas Adams on 6/30/23.
//

import MetalKit
import SwiftUI

import FlexApi
import SettingsModel
import SharedModel

public struct WaterfallView: View {
  var panadapter: Panadapter
  let leftWidth: CGFloat
  
  public init(panadapter: Panadapter, leftWidth: CGFloat) {
    self.panadapter = panadapter
    self.leftWidth = leftWidth
  }

  @Environment(ApiModel.self) private var apiModel

  public var body: some View {
    VStack {
      GeometryReader { g in
        if let waterfall = apiModel.waterfalls[id: panadapter.waterfallId] {
          MetalView(panadapter: panadapter, waterfall: waterfall)
        } else {
          EmptyView()
        }
      }
    }
  }
}

private struct MetalView: NSViewRepresentable {
  var panadapter: Panadapter
  var waterfall: Waterfall

  public typealias NSViewType = MTKView

  public func makeCoordinator() -> WaterfallRenderer {
    WaterfallRenderer(panadapter, waterfall)
  }
  
  public func makeNSView(context: NSViewRepresentableContext<MetalView>) -> MTKView {
    let mtkView = MTKView()
    mtkView.delegate = context.coordinator
    mtkView.preferredFramesPerSecond = 60
    mtkView.enableSetNeedsDisplay = false
    mtkView.isPaused = false

    if let metalDevice = MTLCreateSystemDefaultDevice() {
      mtkView.device = metalDevice
    }
    
    mtkView.framebufferOnly = false
    mtkView.drawableSize = mtkView.frame.size
    
    let color = NSColor(SettingsModel.shared.waterfallClear).usingColorSpace(.sRGB)!
    mtkView.clearColor = MTLClearColorMake(Double(color.redComponent),
                                           Double(color.greenComponent),
                                           Double(color.blueComponent),
                                           Double(color.alphaComponent) )
    return mtkView
  }
  
  public func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalView>) {
  }
}

#Preview {
  WaterfallView(panadapter: Panadapter(0x49999990), leftWidth: 0)
    .frame(width:800, height: 600)
}
