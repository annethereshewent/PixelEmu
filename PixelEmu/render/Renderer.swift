//
//  Renderer.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/4/25.
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
    var state: RendererState

    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    var quadBuffer: MTLBuffer!

    var fillPipelineState: MTLRenderPipelineState!
    var mainPipelineState: MTLRenderPipelineState!
    var debugPipelineState: MTLRenderPipelineState!

    var tiles: [TileState] = [TileState](repeating: TileState(), count: 8)
    var triangleProps: [TriangleProps] = []
    var colorProps: [ColorProps] = []
    var canRender: Bool = false
    var fillRects: [FillRect] = []
    var zProps: [ZProps?] = []
    var textureProps: [TextureProps?] = []
    var currentTile: Int = 0


    init(mtkView: MTKView, state: RendererState) {
        self.state = state
        self.device = mtkView.device!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        quadBuffer = device.makeBuffer(bytes: fullscreenQuad,
                                           length: fullscreenQuad.count * MemoryLayout<TexturedVertex>.stride,
                                           options: [])

        let library = device.makeDefaultLibrary()!
        let vertexBasicFunction = library.makeFunction(name: "vertex_basic")!
        let fragmentBasicFunction = library.makeFunction(name: "fragment_basic")!
        let fragmentMainFunction = library.makeFunction(name: "fragment_main")!
        let vertexMainFunction = library.makeFunction(name: "vertex_main")
        let vertexDebugFunction = library.makeFunction(name: "vertex_debug")
        let fragmentDebugFunction = library.makeFunction(name: "fragment_debug")

        let fillPipelineDescriptor = MTLRenderPipelineDescriptor()
        fillPipelineDescriptor.vertexFunction = vertexBasicFunction
        fillPipelineDescriptor.fragmentFunction = fragmentBasicFunction
        fillPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        let mainPipelineDescriptor = MTLRenderPipelineDescriptor()
        mainPipelineDescriptor.vertexFunction = vertexMainFunction
        mainPipelineDescriptor.fragmentFunction = fragmentMainFunction
        mainPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        let debugPipelineDescriptor = MTLRenderPipelineDescriptor()
        debugPipelineDescriptor.vertexFunction = vertexDebugFunction
        debugPipelineDescriptor.fragmentFunction = fragmentDebugFunction
        debugPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        let vertexDescriptor = MTLVertexDescriptor()

        // Position at attribute(0)
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // UV at attribute(1)
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0

        // Color at attribute(2)
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD2<Float>>.stride * 2
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<RDPVertex>.stride

        let debugVertexDescriptor = MTLVertexDescriptor()

        // Position at attribute(0)
        debugVertexDescriptor.attributes[0].format = .float2
        debugVertexDescriptor.attributes[0].offset = 0
        debugVertexDescriptor.attributes[0].bufferIndex = 0

        // UV at attribute(1)
        debugVertexDescriptor.attributes[1].format = .float2
        debugVertexDescriptor.attributes[1].offset = MemoryLayout<SIMD2<Float>>.stride
        debugVertexDescriptor.attributes[1].bufferIndex = 0

        debugVertexDescriptor.layouts[0].stride = MemoryLayout<TexturedVertex>.stride

        mainPipelineDescriptor.vertexDescriptor = vertexDescriptor
        debugPipelineDescriptor.vertexDescriptor = debugVertexDescriptor

        do {
            fillPipelineState = try device.makeRenderPipelineState(descriptor: fillPipelineDescriptor)
            mainPipelineState = try device.makeRenderPipelineState(descriptor: mainPipelineDescriptor)
            debugPipelineState = try device.makeRenderPipelineState(descriptor: debugPipelineDescriptor)
       } catch {
           fatalError("Failed to create pipeline state: \(error)")
       }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Resize logic goes here if needed
    }

    func draw(in view: MTKView) {
        if state.canRender {
            guard let drawable = view.currentDrawable,
                  let renderPass = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }

            let screenWidth: Float = 320
            let screenHeight: Float = 240

            for rect in state.fillRects {
                let x1 = Float(min(rect.x1, rect.x2))
                let x2 = Float(max(rect.x1, rect.x2) + 1)
                let y1 = Float(min(rect.y1, rect.y2))
                let y2 = Float(max(rect.y1, rect.y2) + 1)

                let fx1 = (x1 / screenWidth) * 2.0 - 1.0
                let fx2 = (x2 / screenWidth) * 2.0 - 1.0
                let fy1 = 1.0 - (y1 / screenHeight) * 2.0
                let fy2 = 1.0 - (y2 / screenHeight) * 2.0

                let vertices: [SIMD2<Float>] = [
                    SIMD2(fx1, fy1),
                    SIMD2(fx2, fy1),
                    SIMD2(fx1, fy2),
                    SIMD2(fx2, fy2)
                ]

                var color = SIMD4<Float>(Float((rect.color >> 11) & 0x1f) / 31.0, Float((rect.color >> 6) & 0x1f) / 31.0, Float((rect.color >> 1) & 0x1f) / 31.0, Float((rect.color) & 1))

                let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD2<Float>>.stride, options: [])

                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)

                encoder.setRenderPipelineState(fillPipelineState)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            }

//            if state.triangleProps.count > 0 {
//                guard let drawable = view.currentDrawable,
//                      let descriptor = view.currentRenderPassDescriptor,
//                      let commandBuffer = commandQueue.makeCommandBuffer(),
//                      let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
//                    return
//                }
//
//                let index = Int.random(in: 0..<state.tiles[state.currentTile].textures.count)
//
//                // print("currentTile has \(state.tiles[state.currentTile].textures.count) textures")
//
//                encoder.setRenderPipelineState(debugPipelineState)
//                encoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
//                encoder.setFragmentTexture(state.tiles[state.currentTile].textures[index], index: 0)
//                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
//
//                encoder.endEncoding()
//                commandBuffer.present(drawable)
//                commandBuffer.commit()
//
//                state.tiles[state.currentTile].textures = []
//            }
            if state.triangleProps.count > 0 {
                for i in 0..<state.triangleProps.count {
                    let triangle = state.triangleProps[i]

                    var rdpVertices = [
                        RDPVertex(),
                        RDPVertex(),
                        RDPVertex()
                    ]

                    let vertices = [
                        SIMD2<Float>((Float(triangle.xl) / screenWidth) * 2.0 - 1.0, 1.0 - (Float(triangle.yl) / screenHeight) * 2.0),
                        SIMD2<Float>((Float(triangle.xm) / screenWidth) * 2.0 - 1.0, 1.0 - (Float(triangle.ym) / screenHeight) * 2.0),
                        SIMD2<Float>((Float(triangle.xh) / screenWidth) * 2.0 - 1.0, 1.0 - (Float(triangle.yh) / screenHeight) * 2.0),
                    ]

                    rdpVertices[0].position = vertices[0]
                    rdpVertices[1].position = vertices[1]
                    rdpVertices[2].position = vertices[2]

                    let baseX = triangle.xl
                    let baseY = triangle.yl

                    let color = state.colorProps[i]

                    let r0 = color.r
                    let g0 = color.g
                    let b0 = color.b
                    let a0 = color.a

                    let r1 = r0 + color.drdx * (triangle.xm - baseX) + color.drdy * (triangle.ym - baseY)
                    let g1 = g0 + color.dgdx * (triangle.xm - baseX) + color.dgdy * (triangle.ym - baseY)
                    let b1 = b0 + color.dbdx * (triangle.xm - baseX) + color.dbdy * (triangle.ym - baseY)
                    let a1 = a0 + color.dadx * (triangle.xm - baseX) + color.dady * (triangle.ym - baseY)

                    let r2 = r0 + color.drdx * (triangle.xh - baseX) + color.drdy * (triangle.yh - baseY)
                    let g2 = g0 + color.dgdx * (triangle.xh - baseX) + color.dgdy * (triangle.yh - baseY)
                    let b2 = b0 + color.dbdx * (triangle.xh - baseX) + color.dbdy * (triangle.yh - baseY)
                    let a2 = a0 + color.dadx * (triangle.xh - baseX) + color.dady * (triangle.yh - baseY)

                    let color0 = simd_clamp(SIMD4<Float>(Float(r0) / 255.0, Float(g0) / 255.0, Float(b0) / 255.0, Float(a0) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
                    let color1 = simd_clamp(SIMD4<Float>(Float(r1) / 255.0, Float(g1) / 255.0, Float(b1) / 255.0, Float(a1) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
                    let color2 = simd_clamp(SIMD4<Float>(Float(r2) / 255.0, Float(g2) / 255.0, Float(b2) / 255.0, Float(a2) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))

                    rdpVertices[0].color = color0
                    rdpVertices[1].color = color1
                    rdpVertices[2].color = color2

                    let tile = state.tiles[currentTile]

                    let sampler = makeSampler(clampS: tile.tileProps.clampSBit, clampT: tile.tileProps.clampTBit)

                    encoder.setFragmentSamplerState(sampler, index: 0)

                    var uniforms = FragmentUniforms(hasTexture: false)

                    if let texture = triangle.texture {
                        encoder.setFragmentTexture(texture, index: 0)
                    }

                    if let texture = state.textureProps[i] {
                        uniforms.hasTexture = true

                        let u0 = texture.s
                        let v0 = texture.t
                        let w0 = texture.w

                        let u1 = u0 + texture.dsdx * (triangle.xm - baseX) + texture.dsdy * (triangle.ym - baseY)
                        let u2 = u0 + texture.dsdx * (triangle.xh - baseX) + texture.dsdy * (triangle.yh - baseY)

                        let v1 = v0 + texture.dtdx * (triangle.xm - baseX) + texture.dtdy * (triangle.ym - baseY)
                        let v2 = v0 + texture.dtdx * (triangle.xh - baseX) + texture.dtdy * (triangle.yh - baseY)

                        let w1 = w0 + texture.dwdx * (triangle.xm - baseX) + texture.dwdy * (triangle.ym - baseY)
                        let w2 = w0 + texture.dwdx * (triangle.xh - baseX) + texture.dwdy * (triangle.yh - baseY)

                        print("u0 = \(u0) v0 = \(v0) w0 = \(w0)")
                        print("u1 = \(u1) v1 = \(v1) w1 = \(w1)")
                        print("u2 = \(u2) v2 = \(v2) w2 = \(w2)")

                        let uv0 = SIMD2<Float>(Float(u0) / Float(w0), Float(v0) / Float(w0))
                        let uv1 = SIMD2<Float>(Float(u1) / Float(w1), Float(v1) / Float(w1))
                        let uv2 = SIMD2<Float>(Float(u2) / Float(w2), Float(v2) / Float(w2))

                        rdpVertices[0].uv = uv0
                        rdpVertices[1].uv = uv1
                        rdpVertices[2].uv = uv2
                    }

                    let vertexBuffer = device.makeBuffer(
                        bytes: rdpVertices,
                        length: MemoryLayout<RDPVertex>.stride * vertices.count,
                        options: []
                    )

                    encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 1)
                    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                    encoder.setRenderPipelineState(mainPipelineState)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
            }

            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()

            state.fillRects = []
            state.colorProps = []
            state.textureProps = []
            state.zProps = []
            state.triangleProps = []
            state.canRender = false
        }
    }

    func makeSolidColorTexture(color: SIMD4<UInt8>, size: Int = 64) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .rgba8Unorm
        descriptor.width = size
        descriptor.height = size
        descriptor.usage = [.shaderRead]
        descriptor.storageMode = .shared

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }

        // Fill pixel buffer with RGBA values
        var pixelData = [UInt8](repeating: 0, count: size * size * 4)
        for i in 0..<size*size {
            pixelData[i * 4 + 0] = color.x // R
            pixelData[i * 4 + 1] = color.y // G
            pixelData[i * 4 + 2] = color.z // B
            pixelData[i * 4 + 3] = color.w // A
        }

        let region = MTLRegionMake2D(0, 0, size, size)
        texture.replace(region: region, mipmapLevel: 0, withBytes: pixelData, bytesPerRow: size * 4)

        return texture
    }

    func makeSampler(clampS: Bool, clampT: Bool) -> MTLSamplerState {
        let desc = MTLSamplerDescriptor()
        desc.minFilter = .nearest
        desc.magFilter = .nearest
        desc.sAddressMode = clampS ? .clampToEdge : .repeat
        desc.tAddressMode = clampT ? .clampToEdge : .repeat
        return device.makeSamplerState(descriptor: desc)!
    }
}
