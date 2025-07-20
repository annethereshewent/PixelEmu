//
//  Renderer.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/19/25.
//

import Metal
import MetalKit

let fullscreenQuad: [TexturedVertex] = [
    TexturedVertex(position: [-1,  1], uv: [0, 0]), // top-left
    TexturedVertex(position: [ 1,  1], uv: [1, 0]), // top-right
    TexturedVertex(position: [-1, -1], uv: [0, 1]), // bottom-left
    TexturedVertex(position: [ 1, -1], uv: [1, 1])  // bottom-right
]

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    var quadBuffer: MTLBuffer!

    var quadPipelineState: MTLRenderPipelineState!
    var outputTexture: MTLTexture!

    init(mtkView: MTKView) {
        let quadPipelineDescriptor = MTLRenderPipelineDescriptor()
        quadPipelineDescriptor.vertexFunction = vertexDebugFunction
        quadPipelineDescriptor.fragmentFunction = fragmentDebugFunction
        quadPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        quadPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
    }
}
