//
//  Renderer.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/4/25.
//

import Metal
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    init(mtkView: MTKView) {
        self.device = mtkView.device!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Resize logic goes here if needed
    }

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        // For now, just clear the screen
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
