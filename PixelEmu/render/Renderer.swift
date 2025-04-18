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

//            encoder.setFrontFacing(.counterClockwise)
//            encoder.setCullMode(.none)

            let passDescriptor = view.currentRenderPassDescriptor!
            passDescriptor.depthAttachment.texture = depthTexture
            passDescriptor.depthAttachment.loadAction = .clear
            passDescriptor.depthAttachment.storeAction = .store
            passDescriptor.depthAttachment.clearDepth = 1.0

            let screenWidth: Float = 320
            let screenHeight: Float = 240

//            encoder.setDepthStencilState(depthDisabledState)
            if state.fillRects.count > 0 {
                guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
                    return
                }
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
                encoder.endEncoding()
            }

            if state.triangleProps.count > 0 {
                var triangles: [Triangle] = []

                for i in 0..<state.triangleProps.count {
                    let props = state.triangleProps[i]
                    let textureWidth = state.tiles[state.currentTile].shi - state.tiles[state.currentTile].slo + 1
                    let textureHeight = state.tiles[state.currentTile].thi - state.tiles[state.currentTile].tlo + 1
                    var triangle = Triangle(
                        xl: props.xl,
                        xh: props.xh,
                        xm: props.xm,

                        yl: props.yl,
                        yh: props.yh,
                        ym: props.ym,

                        dxldy: props.dxldy,
                        dxmdy: props.dxmdy,
                        dxhdy: props.dxhdy,

                        bufferOffset: props.bufferOffset,
                        validTexelCount: props.validTexelCount,

                        flip: props.flip,

                        tileProps: state.tiles[state.currentTile].tileProps
                    )

                    let color = state.colorProps[i]

                    triangle.rgba = SIMD4<Float>(color.r, color.g, color.b, color.a)

                    triangle.drdx_dgdx_dbdx_dadx = SIMD4<Float>(
                        color.drdx,
                        color.dgdx,
                        color.dbdx,
                        color.dadx
                    )

                    triangle.drdy_dgdy_dbdy_dady = SIMD4<Float>(
                        color.drdy,
                        color.dgdy,
                        color.dbdy,
                        color.dady
                    )

                    triangle.drde_dgde_dbde_dade = SIMD4<Float>(
                        color.drde,
                        color.dgde,
                        color.dbde,
                        color.dade
                    )

                    if let texture = state.textureProps[i] {
                        triangle.stw = SIMD3<Float>(texture.s, texture.t, texture.w)

                        triangle.dsdx_dtdx_dwdx = SIMD3<Float>(
                            texture.dsdx,
                            texture.dtdx,
                            texture.dwdx
                        )

                        triangle.dsdy_dtdy_dwdy = SIMD3<Float>(
                            texture.dsdy,
                            texture.dtdy,
                            texture.dwdy
                        )

                        triangle.dsde_dtde_dwde = SIMD3<Float>(
                            texture.dsde,
                            texture.dtde,
                            texture.dwde
                        )

                        triangle.hasTexture = 1
                    }

                    triangles.append(triangle)
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

                clearEncoder.setComputePipelineState(clearPipelineState)
                clearEncoder.setTexture(outputTexture, index: 0)
                // dispatch threadgroups
                clearEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
                clearEncoder.endEncoding()


                threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)
                threadgroups = MTLSize(
                    width: triangles.count,
                    height: 1,
                    depth: 1
                )

                guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                    return
                }

                let textureDataBuffer = device.makeBuffer(bytes: rendererState.textureBuffer, length: rendererState.textureBuffer.count, options: [])
                let triangleBuffer = device.makeBuffer(bytes: triangles, length: MemoryLayout<Triangle>.stride * triangles.count, options: [])

                computeEncoder.setBuffer(triangleBuffer, offset: 0, index: 0)
                computeEncoder.setBuffer(textureDataBuffer, offset: 0, index: 1)
                computeEncoder.setTexture(outputTexture, index: 0)
                computeEncoder.setComputePipelineState(computePipelineState)
                computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
                computeEncoder.endEncoding()
            }

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

            state.fillRects = []
            state.colorProps = []
            state.textureProps = []
            state.zProps = []
            state.triangleProps = []
            state.canRender = false
            state.textureBuffer = []
        }
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
