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
    var quadPipelineState: MTLRenderPipelineState!

    var computePipelineState: MTLComputePipelineState!
    var clearPipelineState: MTLComputePipelineState!

    var depthTexture: MTLTexture!
    var depthStencilState: MTLDepthStencilState!
    var depthDisabledState: MTLDepthStencilState!

    var outputTexture: MTLTexture!

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

        let quadPipelineDescriptor = MTLRenderPipelineDescriptor()
        quadPipelineDescriptor.vertexFunction = vertexDebugFunction
        quadPipelineDescriptor.fragmentFunction = fragmentDebugFunction
        quadPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        quadPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        guard let clearFunction = library.makeFunction(name: "clear_framebuffer") else {
            fatalError("Missing clear shader")
        }

        guard let renderFunction = library.makeFunction(name: "rasterize_triangle") else {
            fatalError("Failed to find compute function!")
        }

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
        quadPipelineDescriptor.vertexDescriptor = debugVertexDescriptor

        depthTexture = buildDepthTexture(for: mtkView)

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: 320,
            height: 240,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        outputTexture = device.makeTexture(descriptor: textureDescriptor)!

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
            quadPipelineState = try device.makeRenderPipelineState(descriptor: quadPipelineDescriptor)
            computePipelineState = try device.makeComputePipelineState(function: renderFunction)
            clearPipelineState = try device.makeComputePipelineState(function: clearFunction)
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
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            var threadsPerThreadgroup = MTLSize(width: 8, height: 8, depth: 1)
            var threadgroups = MTLSize(
                width: (320 + 7) / 8,
                height: (240 + 7) / 8,
                depth: 1
            )

            guard let clearEncoder = commandBuffer.makeComputeCommandEncoder() else {
                return
            }

            let fence = device.makeFence()!

            clearEncoder.setComputePipelineState(clearPipelineState)
            clearEncoder.setTexture(outputTexture, index: 0)
            // dispatch threadgroups
            clearEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
            clearEncoder.updateFence(fence)
            clearEncoder.endEncoding()

            let triangleVertices: [RDPVertex] = [
                RDPVertex(position: SIMD3<Float>(160, 50, 1), uv: SIMD2<Float>(0, 0), color: SIMD4<Float>(1, 0, 0, 1)), // Top
                RDPVertex(position: SIMD3<Float>(100, 190, 1), uv: SIMD2<Float>(0, 0), color: SIMD4<Float>(0, 1, 0, 1)), // Bottom left
                RDPVertex(position: SIMD3<Float>(220, 190, 1), uv: SIMD2<Float>(0, 0), color: SIMD4<Float>(0, 0, 1, 1))  // Bottom right
            ]

            let triangles = [Triangle(v0: triangleVertices[0], v1: triangleVertices[1], v2: triangleVertices[2])]

            threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
            threadgroups = MTLSize(
                width: (triangles.count + 63) / 64,
                height: 1,
                depth: 1
            )

            guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                return
            }

            let triangleBuffer = device.makeBuffer(bytes: triangles, length: MemoryLayout<Triangle>.stride * triangles.count, options: [])

            computeEncoder.setBuffer(triangleBuffer, offset: 0, index: 0)
            computeEncoder.setTexture(outputTexture, index: 0)
            computeEncoder.setComputePipelineState(computePipelineState)
            computeEncoder.waitForFence(fence)
            computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
            computeEncoder.endEncoding()

            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }

            renderEncoder.setRenderPipelineState(quadPipelineState)
            renderEncoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(outputTexture, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()

//            encoder.setFrontFacing(.counterClockwise)
//            encoder.setCullMode(.none)
//
//            let passDescriptor = view.currentRenderPassDescriptor!
//            passDescriptor.depthAttachment.texture = depthTexture
//            passDescriptor.depthAttachment.loadAction = .clear
//            passDescriptor.depthAttachment.storeAction = .store
//            passDescriptor.depthAttachment.clearDepth = 1.0
//
//            let screenWidth: Float = 320
//            let screenHeight: Float = 240
//
//            encoder.setDepthStencilState(depthDisabledState)
//            for rect in state.fillRects {
//                let x1 = Float(min(rect.x1, rect.x2))
//                let x2 = Float(max(rect.x1, rect.x2) + 1)
//                let y1 = Float(min(rect.y1, rect.y2))
//                let y2 = Float(max(rect.y1, rect.y2) + 1)
//
//                let fx1 = (x1 / screenWidth) * 2.0 - 1.0
//                let fx2 = (x2 / screenWidth) * 2.0 - 1.0
//                let fy1 = 1.0 - (y1 / screenHeight) * 2.0
//                let fy2 = 1.0 - (y2 / screenHeight) * 2.0
//
//                let vertices: [SIMD2<Float>] = [
//                    SIMD2(fx1, fy1),
//                    SIMD2(fx2, fy1),
//                    SIMD2(fx1, fy2),
//                    SIMD2(fx2, fy2)
//                ]
//
//                var color = SIMD4<Float>(Float((rect.color >> 11) & 0x1f) / 31.0, Float((rect.color >> 6) & 0x1f) / 31.0, Float((rect.color >> 1) & 0x1f) / 31.0, Float((rect.color) & 1))
//
//                let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD2<Float>>.stride, options: [])
//
//                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//                encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
//
//                encoder.setRenderPipelineState(fillPipelineState)
//                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
//            }

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
//                encoder.setRenderPipelineState(quadPipelineState)
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
//            if state.triangleProps.count > 0 {
//                var previousVerts: [SIMD2<Float>] = []
//                for i in 0..<state.triangleProps.count {
//                    let triangle = state.triangleProps[i]
//
////                    var y0 = triangle.yh
////                    var x0 = triangle.xh
////
////                    var y1 = triangle.ym
////                    var x1 = triangle.flip ? triangle.xh - triangle.dxhdy * (y1 - y0) : triangle.xh + triangle.dxhdy * (y1 - y0)
////
////                    var y2 = triangle.yl
////                    var x2 = triangle.xl
//
//                    var y0 = triangle.yh
//                    var x0 = triangle.xh
//
////                    var y1 = triangle.ym
////                    var x1 = triangle.flip ? triangle.xm - triangle.dxmdy * (y1 - y0) : triangle.xm + triangle.dxmdy * (y1 - y0)
////
////                    var y2 = triangle.yl
////                    var x2 = triangle.flip ? triangle.xl + triangle.dxldy * (y2 - y1) : triangle.xl - triangle.dxldy * (y2 - y1)
//
//                    var x2 = triangle.xl
//                    var y2 = triangle.ym
//
//                    var y1 = triangle.yl
//                    var x1 = triangle.flip ? triangle.xl + triangle.dxldy * (y2 - y1) : triangle.xl - triangle.dxldy * (y2 - y1)
//
//                    if triangle.flip {
//                        let tempX = x1
//                        x1 = x2
//                        x2 = tempX
//
//                        let tempY = y1
//                        y1 = y2
//                        y2 = tempY
//                    }
//
//                    let verts = [
//                        SIMD2<Float>(x0, y0),
//                        SIMD2<Float>(x1, y1),
//                        SIMD2<Float>(x2, y2)
//                    ]
//
//                    print("v0: (\(x0), \(y0)) v1: (\(x1), \(y1)) v2: (\(x2), \(y2))")
//                    print("dxhdy: \(triangle.dxhdy), dxmdy: \(triangle.dxmdy), dxldy: \(triangle.dxldy)")
//
//                    let area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
//
//                    if area == 0 && previousVerts.count > 0 {
//                        // need to redefine xl, xm, xh, etc
//                        // xh = x0 xm = x1 xl = x2 yh = y0 ym = y1 yl = y2
//                        x0 = previousVerts[0].x
//                        y0 = previousVerts[0].y
//
//                        x2 = previousVerts[2].x
//                        y2 = previousVerts[2].y
//
//                        x1 = previousVerts[2].x
//                        y1 = previousVerts[0].y
//                    }
//
//                    var rdpVertices = [
//                        RDPVertex(),
//                        RDPVertex(),
//                        RDPVertex()
//                    ]
//
//                    let baseX = x0
//                    let baseY = y0
//
//                    var z0: Float = 1.0
//                    var z1: Float = 1.0
//                    var z2: Float = 1.0
//
//                    let depthNorm: Float = Float(0x7fff)
//
//                    if let z = state.zProps[i] {
//                        z0 = z.z
//
//                        z1 = z0 + z.dzdx * (x1 - baseX) + z.dzdy * (y1 - baseY)
//                        z2 = z0 + z.dzdx * (x2 - baseX) + z.dzdy * (y2 - baseY)
//
//                        z0 /= depthNorm
//                        z1 /= depthNorm
//                        z2 /= depthNorm
//
//                        encoder.setDepthStencilState(depthStencilState)
//                    } else {
//                        encoder.setDepthStencilState(depthDisabledState)
//                    }
//
//                    let vertices = [
//                        SIMD3<Float>((x0 / screenWidth) * 2.0 - 1.0, 1.0 - (y0 / screenHeight) * 2.0, z0),
//                        SIMD3<Float>((x1 / screenWidth) * 2.0 - 1.0, 1.0 - (y1 / screenHeight) * 2.0, z1),
//                        SIMD3<Float>((x2 / screenWidth) * 2.0 - 1.0, 1.0 - (y2 / screenHeight) * 2.0, z2),
//                    ]
//
//                    rdpVertices[0].position = vertices[0]
//                    rdpVertices[1].position = vertices[1]
//                    rdpVertices[2].position = vertices[2]
//
//                    previousVerts = verts
//
//                    let color = state.colorProps[i]
//
//                    let r0 = color.r
//                    let g0 = color.g
//                    let b0 = color.b
//                    let a0 = color.a
//
//                    let r1 = r0 + color.drdx * (x1 - baseX) + color.drdy * (y1 - baseY)
//                    let g1 = g0 + color.dgdx * (x1 - baseX) + color.dgdy * (y1 - baseY)
//                    let b1 = b0 + color.dbdx * (x1 - baseX) + color.dbdy * (y1 - baseY)
//                    let a1 = a0 + color.dadx * (x1 - baseX) + color.dady * (y1 - baseY)
//
//                    let r2 = r0 + color.drdx * (x2 - baseX) + color.drdy * (y2 - baseY)
//                    let g2 = g0 + color.dgdx * (x2 - baseX) + color.dgdy * (y2 - baseY)
//                    let b2 = b0 + color.dbdx * (x2 - baseX) + color.dbdy * (y2 - baseY)
//                    let a2 = a0 + color.dadx * (x2 - baseX) + color.dady * (y2 - baseY)
//
//                    let color0 = simd_clamp(SIMD4<Float>(Float(r0) / 255.0, Float(g0) / 255.0, Float(b0) / 255.0, Float(a0) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
//                    let color1 = simd_clamp(SIMD4<Float>(Float(r1) / 255.0, Float(g1) / 255.0, Float(b1) / 255.0, Float(a1) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
//                    let color2 = simd_clamp(SIMD4<Float>(Float(r2) / 255.0, Float(g2) / 255.0, Float(b2) / 255.0, Float(a2) / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
//
//                    rdpVertices[0].color = color0
//                    rdpVertices[1].color = color1
//                    rdpVertices[2].color = color2
//
//                    let tile = state.tiles[state.currentTile]
//
//                    let textureHeight = Float(tile.thi - tile.tlo + 1)
//                    let textureWidth = Float(tile.shi - tile.slo + 1)
//
//                    let sampler = makeSampler(mirrorS: tile.tileProps.mirrorSBit, mirrorT: tile.tileProps.mirrorTBit)
//
//                    encoder.setFragmentSamplerState(sampler, index: 0)
//
//                    var uniforms = FragmentUniforms(
//                        hasTexture: false,
//                        clampS: tile.tileProps.clampSBit,
//                        clampT: tile.tileProps.clampTBit
//                    )
//
//                    if let texture = triangle.texture {
//                        encoder.setFragmentTexture(texture, index: 0)
//                    }
//
//                    if var texture = state.textureProps[i] {
//                        uniforms.hasTexture = true
//
//                        let scale: Float = 16
//
//                        let u0 = texture.s
//                        let v0 = texture.t
//                        let w0 = texture.w
//
//                        let dx1 = x1 - x0
//                        let dy1 = y1 - y0
//
//                        let u1 = u0 + texture.dsdx * dx1 + texture.dsdy * dy1
//                        let v1 = v0 + texture.dtdx * dx1 + texture.dtdy * dy1
//                        let w1 = w0 + texture.dwdx * dx1 + texture.dwdy * dy1
//
//                        let dx2 = x2 - x0
//                        let dy2 = y2 - y0
//
//                        let u2 = u0 + texture.dsdx * dx2 + texture.dsdy * dy2
//                        let v2 = v0 + texture.dtdx * dx2 + texture.dtdy * dy2
//                        let w2 = w0 + texture.dwdx * dx2 + texture.dwdy * dy2
//
//                        var uv0 = SIMD2<Float>(Float(u0) / Float(w0), 1.0 - Float(v0) / Float(w0))
//                        var uv1 = SIMD2<Float>(Float(u1) / Float(w1), 1.0 - Float(v1) / Float(w1))
//                        var uv2 = SIMD2<Float>(Float(u2) / Float(w2), 1.0 - Float(v2) / Float(w2))
//
////                        uv0 = SIMD2<Float>(1.0, 0.0)
////                        uv1 = SIMD2<Float>(1.0, 1.0)
////                        uv2 = SIMD2<Float>(0.0, 0.0)
//
////                        uv0 = SIMD2<Float>(0.0, 0.0)
////                        uv1 = SIMD2<Float>(0.0, 1.0)
////                        uv2 = SIMD2<Float>(1.0, 1.0)
//
////                        let multiplier = Float(textureHeight) / Float(triangle.validHeight)
////
////                        uv0.y *= multiplier
////                        uv1.y *= multiplier
////                        uv2.y *= multiplier
//
//                        rdpVertices[0].uv = uv0
//                        rdpVertices[1].uv = uv1
//                        rdpVertices[2].uv = uv2
//                    }
//
//                    let vertexBuffer = device.makeBuffer(
//                        bytes: rdpVertices,
//                        length: MemoryLayout<RDPVertex>.stride * vertices.count,
//                        options: []
//                    )
//
//                    encoder.setFragmentBytes(&uniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 1)
//                    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//                    encoder.setRenderPipelineState(mainPipelineState)
//                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
//                }
//            }
//
//            encoder.endEncoding()
//            commandBuffer.present(drawable)
//            commandBuffer.commit()

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
