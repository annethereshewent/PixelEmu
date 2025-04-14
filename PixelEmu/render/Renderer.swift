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

    var depthTexture: MTLTexture!
    var depthStencilState: MTLDepthStencilState!
    var depthDisabledState: MTLDepthStencilState!

    func buildDepthTexture(for view: MTKView) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .depth32Float,
            width: 320,
            height: 240,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget]
        descriptor.storageMode = .private
        return device.makeTexture(descriptor: descriptor)
    }


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
        fillPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let mainPipelineDescriptor = MTLRenderPipelineDescriptor()
        mainPipelineDescriptor.vertexFunction = vertexMainFunction
        mainPipelineDescriptor.fragmentFunction = fragmentMainFunction
        mainPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        mainPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let debugPipelineDescriptor = MTLRenderPipelineDescriptor()
        debugPipelineDescriptor.vertexFunction = vertexDebugFunction
        debugPipelineDescriptor.fragmentFunction = fragmentDebugFunction
        debugPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        debugPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        let vertexDescriptor = MTLVertexDescriptor()

        // Position at attribute(0)
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // UV at attribute(1)
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = 16
        vertexDescriptor.attributes[1].bufferIndex = 0

        // Color at attribute(2)
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = 32
        vertexDescriptor.attributes[2].bufferIndex = 0

//        print(MemoryLayout.offset(of: \RDPVertex.position))
//        print(MemoryLayout.offset(of: \RDPVertex.uv))
//        print(MemoryLayout.offset(of: \RDPVertex.color))
//
//        if MemoryLayout<RDPVertex>.stride != 36 {
//            fatalError("it doesn't equal: \(MemoryLayout<RDPVertex>.stride)")
//        }

        vertexDescriptor.layouts[0].stride = 48

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

        depthTexture = buildDepthTexture(for: mtkView)

        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true

        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)

        let depthDisabledDesc = MTLDepthStencilDescriptor()
        depthDisabledDesc.depthCompareFunction = .always
        depthDisabledDesc.isDepthWriteEnabled = false

        depthDisabledState = device.makeDepthStencilState(descriptor: depthDisabledDesc)

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

            encoder.setFrontFacing(.counterClockwise)
            encoder.setCullMode(.none)

            let passDescriptor = view.currentRenderPassDescriptor!
            passDescriptor.depthAttachment.texture = depthTexture
            passDescriptor.depthAttachment.loadAction = .clear
            passDescriptor.depthAttachment.storeAction = .store
            passDescriptor.depthAttachment.clearDepth = 1.0

            let screenWidth: Float = 320
            let screenHeight: Float = 240

            encoder.setDepthStencilState(depthDisabledState)
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

//            if state.triangleProps.count > 0 && state.tiles[0].textures.count > 0 {
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
                var previousProps = TriangleProps()
                for i in 0..<state.triangleProps.count {
                    var triangle = state.triangleProps[i]

                    let area = (triangle.xm - triangle.xh) * (triangle.yl - triangle.yh) - (triangle.xl - triangle.xh) * (triangle.ym - triangle.yh)

                    if area == 0 {
                        // need to redefine xl, xm, xh, etc
                        // xh = x0 xm = x1 xl = x2 yh = y0 ym = y1 yl = y2
//                        triangle.xh = previousProps.xl
//                        triangle.yh = previousProps.yl
//
//                        triangle.xl = previousProps.xh
//                        triangle.yl = previousProps.yl
//
//                        triangle.xm = previousProps.xh
//                        triangle.ym = previousProps.yh
//
//                        let area = (triangle.xm - triangle.xh) * (triangle.yl - triangle.yh) - (triangle.xl - triangle.xh) * (triangle.ym - triangle.yh)
//
//                        print(area)

                        triangle.xh = previousProps.xh
                        triangle.yh = previousProps.yh

                        triangle.xl = previousProps.xl
                        triangle.yl = previousProps.yl

                        triangle.xm = previousProps.xl
                        triangle.ym = previousProps.yh
                    }

                    var rdpVertices = [
                        RDPVertex(),
                        RDPVertex(),
                        RDPVertex()
                    ]

                    let baseX = triangle.xh
                    let baseY = triangle.yh

                    var z0: Float = 1.0
                    var z1: Float = 1.0
                    var z2: Float = 1.0

                    let depthNorm: Float = Float(0x7fff)

                    if let z = state.zProps[i] {
                        z0 = Float(z.z)

                        z1 = z0 + z.dzdx * (triangle.xm - baseX) + z.dzdy * (triangle.ym - baseY)
                        z2 = z0 + z.dzdx * (triangle.xl - baseX) + z.dzdy * (triangle.yl - baseY)

                        z0 /= depthNorm
                        z1 /= depthNorm
                        z2 /= depthNorm

                        encoder.setDepthStencilState(depthStencilState)
                    } else {
                        encoder.setDepthStencilState(depthDisabledState)
                    }

                    let vertices = [
                        SIMD3<Float>((Float(triangle.xh) / screenWidth) * 2.0 - 1.0, 1.0 - (Float(triangle.yh) / screenHeight) * 2.0, z0),
                        SIMD3<Float>((Float(triangle.xm) / screenWidth) * 2.0 - 1.0, 1.0 - (Float(triangle.ym) / screenHeight) * 2.0, z1),
                        SIMD3<Float>((Float(triangle.xl) / screenWidth) * 2.0 - 1.0, 1.0 - (Float(triangle.yl) / screenHeight) * 2.0, z2),
                    ]

                    rdpVertices[0].position = vertices[0]
                    rdpVertices[1].position = vertices[1]
                    rdpVertices[2].position = vertices[2]

                    previousProps = triangle

                    let color = state.colorProps[i]

                    let r0 = color.r
                    let g0 = color.g
                    let b0 = color.b
                    let a0 = color.a

                    let r1 = r0 + color.drdx * (triangle.xm - baseX) + color.drdy * (triangle.ym - baseY)
                    let g1 = g0 + color.dgdx * (triangle.xm - baseX) + color.dgdy * (triangle.ym - baseY)
                    let b1 = b0 + color.dbdx * (triangle.xm - baseX) + color.dbdy * (triangle.ym - baseY)
                    let a1 = a0 + color.dadx * (triangle.xm - baseX) + color.dady * (triangle.ym - baseY)

                    let r2 = r0 + color.drdx * (triangle.xl - baseX) + color.drdy * (triangle.yl - baseY)
                    let g2 = g0 + color.dgdx * (triangle.xl - baseX) + color.dgdy * (triangle.yl - baseY)
                    let b2 = b0 + color.dbdx * (triangle.xl - baseX) + color.dbdy * (triangle.yl - baseY)
                    let a2 = a0 + color.dadx * (triangle.xl - baseX) + color.dady * (triangle.yl - baseY)

                    let color0 = simd_clamp(SIMD4<Float>(Float(r0) / 255.0, Float(g0) / 255.0, Float(b0) / 255.0, Float(a0) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
                    let color1 = simd_clamp(SIMD4<Float>(Float(r1) / 255.0, Float(g1) / 255.0, Float(b1) / 255.0, Float(a1) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
                    let color2 = simd_clamp(SIMD4<Float>(Float(r2) / 255.0, Float(g2) / 255.0, Float(b2) / 255.0, Float(a2) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))

                    rdpVertices[0].color = color0
                    rdpVertices[1].color = color1
                    rdpVertices[2].color = color2

                    let tile = state.tiles[state.currentTile]

                    let textureHeight = tile.thi - tile.tlo + 1

                    let sampler = makeSampler(mirrorS: tile.tileProps.mirrorSBit, mirrorT: tile.tileProps.mirrorTBit)

                    encoder.setFragmentSamplerState(sampler, index: 0)

                    var uniforms = FragmentUniforms(
                        hasTexture: false,
                        clampS: tile.tileProps.clampSBit,
                        clampT: tile.tileProps.clampTBit
                    )

                    if let texture = triangle.texture {
                        encoder.setFragmentTexture(texture, index: 0)
                    }

                    let (x0, y0) = (triangle.xh, triangle.yh)
                    let (x1, y1) = (triangle.xm, triangle.ym)
                    let (x2, y2) = (triangle.xl, triangle.yl)

                    if let texture = state.textureProps[i] {
                        uniforms.hasTexture = true

                        let u0 = texture.s
                        let v0 = texture.t
                        let w0 = texture.w

                        let dx1 = x1 - x0
                        let dy1 = y1 - y0

                        let u1 = u0 + texture.dsdx * dx1 + texture.dsdy * dy1
                        let v1 = v0 + texture.dtdx * dx1 + texture.dtdy * dy1
                        let w1 = w0 + texture.dwdx * dx1 + texture.dwdy * dy1

                        let dx2 = x2 - x0
                        let dy2 = y2 - y0

                        let u2 = u0 + texture.dsdx * dx2 + texture.dsdy * dy2
                        let v2 = v0 + texture.dtdx * dx2 + texture.dtdy * dy2
                        let w2 = w0 + texture.dwdx * dx2 + texture.dwdy * dy2

                        var uv0 = SIMD2<Float>(Float(u0) / Float(w0), 1.0 - Float(v0) / Float(w0))
                        var uv1 = SIMD2<Float>(Float(u1) / Float(w1), 1.0 - Float(v1) / Float(w1))
                        var uv2 = SIMD2<Float>(Float(u2) / Float(w2), 1.0 - Float(v2) / Float(w2))

//                        uv0 = SIMD2<Float>(1.0, 0.0)
//                        uv1 = SIMD2<Float>(1.0, 1.0)
//                        uv2 = SIMD2<Float>(0.0, 0.0)

//                        uv0 = SIMD2<Float>(0.0, 0.0)
//                        uv1 = SIMD2<Float>(0.0, 1.0)
//                        uv2 = SIMD2<Float>(1.0, 1.0)

//                        let multiplier = Float(textureHeight) / Float(triangle.validHeight)
//
//                        uv0.y *= multiplier
//                        uv1.y *= multiplier
//                        uv2.y *= multiplier

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

    func makeSampler(mirrorS: Bool, mirrorT: Bool) -> MTLSamplerState {
        let desc = MTLSamplerDescriptor()
        desc.minFilter = .nearest
        desc.magFilter = .nearest
        desc.sAddressMode = mirrorS ? .mirrorRepeat : .repeat
        desc.tAddressMode = mirrorT ? .mirrorRepeat : .repeat
        return device.makeSamplerState(descriptor: desc)!
    }
}
