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

let WIDTH = 160
let HEIGHT = 144

struct TexturedVertex {
    var position: SIMD2<Float>
    var uv: SIMD2<Float>
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    var quadBuffer: MTLBuffer!

    var quadPipelineState: MTLRenderPipelineState!
    var outputTexture: MTLTexture!

    var renderingData: RenderingData

    init(mtkView: MTKView, renderingData: RenderingData) {
        self.renderingData = renderingData
        self.device = mtkView.device!
        let library = device.makeDefaultLibrary()!

        self.renderingData.mtkView = mtkView

        quadBuffer = device.makeBuffer(bytes: fullscreenQuad,
           length: fullscreenQuad.count * MemoryLayout<TexturedVertex>.stride,
           options: []
        )

        commandQueue = device.makeCommandQueue()!

        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")

        let quadPipelineDescriptor = MTLRenderPipelineDescriptor()
        quadPipelineDescriptor.vertexFunction = vertexFunction
        quadPipelineDescriptor.fragmentFunction = fragmentFunction
        quadPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        quadPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let vertexDescriptor = MTLVertexDescriptor()

        // Position at attribute(0)
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // UV at attribute(1)
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<TexturedVertex>.stride

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: 160,
            height: 144,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        outputTexture = device.makeTexture(descriptor: textureDescriptor)!


        do {
            quadPipelineState = try device.makeRenderPipelineState(descriptor: quadPipelineDescriptor)
        } catch {
            fatalError("\(error)")
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }

    func draw(in view: MTKView) {
        renderingData.shouldStep = true
        if let framebuffer = renderingData.framebuffer {
            guard let drawable = view.currentDrawable,
                  let renderPass = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }

            let region = MTLRegionMake2D(0, 0, WIDTH, HEIGHT)

            outputTexture.replace(
                region: region,
                mipmapLevel: 0,
                withBytes: framebuffer,
                bytesPerRow: WIDTH * 4
            )

            renderEncoder.setRenderPipelineState(quadPipelineState)
            renderEncoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(outputTexture, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            renderEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
