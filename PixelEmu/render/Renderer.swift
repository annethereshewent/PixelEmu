//
//  Renderer.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/4/25.
//

import Metal
import MetalKit

enum CycleType {
    case cycle1
}
struct FillRect {
    var x1: UInt32 = 0
    var x2: UInt32 = 0
    var y1: UInt32 = 0
    var y2: UInt32 = 0
    var color: UInt32 = 0
}

struct ZProps {
    var z: Float = 0
    var dzdx: Float = 0
    var dzdy: Float = 0
    var dzde: Float = 0
}

struct TriangleProps {
    var yl: Float = 0
    var ym: Float = 0
    var yh: Float = 0

    var xl: Float = 0
    var xm: Float = 0
    var xh: Float = 0
    var flip = false
    var tile: UInt32 = 0
    var doOffset = false

    var dxldy: Float = 0
    var dxmdy: Float = 0
    var dxhdy: Float = 0
}

struct TextureProps {
    var s: Float = 0
    var t: Float = 0
    var w: Float = 0

    var dsdx: Float = 0
    var dtdx: Float = 0
    var dwdx: Float = 0

    var dsde: Float = 0
    var dtde: Float = 0
    var dwde: Float = 0

    var dsdy: Float = 0
    var dtdy: Float = 0
    var dwdy: Float = 0
}

struct RDPVertex {
    var position: SIMD2<Float> = SIMD2<Float>(0, 0)
    var uv: SIMD2<Float> = SIMD2<Float>(0, 0)
    var color: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 0)
}

struct ColorProps {
    var r: Float = 0
    var g: Float = 0
    var b: Float = 0

    var a: Float = 0

    var drdx: Float = 0
    var drdy: Float = 0
    var drde: Float = 0

    var dgdx: Float = 0
    var dgdy: Float = 0
    var dgde: Float = 0

    var dbdx: Float = 0
    var dbdy: Float = 0
    var dbde: Float = 0

    var dadx: Float = 0
    var dady: Float = 0
    var dade: Float = 0
}

struct RDPState {
    var cycleType: CycleType = .cycle1
    var enableZTest: Bool = true
    var enableAlphaBlend: Bool = true
    var enableTextureLod: Bool = false
    var coverageMode: Int = 0
    var dither: Int = 0
}

enum RdpCommand: UInt32 {
    case Nop = 0
    case MetaSignalTimeline = 1
    case MetaFlush = 2
    case MetaIdle = 3
    case MetaSetQuirks = 4
    case FillTriangle = 0x08
    case FillZBufferTriangle = 0x09
    case TextureTriangle = 0x0a
    case TextureZBufferTriangle = 0x0b
    case ShadeTriangle = 0x0c
    case ShadeZBufferTriangle = 0x0d
    case ShadeTextureTriangle = 0x0e
    case ShadeTextureZBufferTriangle = 0x0f
    case TextureRectangle = 0x24
    case TextureRectangleFlip = 0x25
    case SyncLoad = 0x26
    case SyncPipe = 0x27
    case SyncTile = 0x28
    case SyncFull = 0x29
    case SetKeyGB = 0x2a
    case SetKeyR = 0x2b
    case SetConvert = 0x2c
    case SetScissor = 0x2d
    case SetPrimDepth = 0x2e
    case SetOtherModes = 0x2f
    case LoadTLut = 0x30
    case SetTileSize = 0x32
    case LoadBlock = 0x33
    case LoadTile = 0x34
    case SetTile = 0x35
    case FillRectangle = 0x36
    case SetFillColor = 0x37
    case SetFogColor = 0x38
    case SetBlendColor = 0x39
    case SetPrimColor = 0x3a
    case SetEnvColor = 0x3b
    case SetCombine = 0x3c
    case SetTextureImage = 0x3d
    case SetMaskImage = 0x3e
    case SetColorImage = 0x3f
}

class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    var rdpState = RDPState()

    var fillPipelineState: MTLRenderPipelineState!
    var mainPipelineState: MTLRenderPipelineState!

    var enqueuedWords: [[UInt32]] = []

    var fillColor: UInt32 = 0
    var fillRects: [FillRect] = []
    var triangleProps: [TriangleProps] = []
    var textureProps: [TextureProps] = []
    var colorProps: [ColorProps] = []
    var zProps: [ZProps] = []

    var canRender = false

    init(mtkView: MTKView, enqueuedWords: [[UInt32]]) {
        self.device = mtkView.device!
        self.commandQueue = device.makeCommandQueue()!
        self.enqueuedWords = enqueuedWords
        super.init()

        let library = device.makeDefaultLibrary()!
        let vertexBasicFunction = library.makeFunction(name: "vertex_basic")!
        let fragmentFunction = library.makeFunction(name: "fragment_main")!
        let vertexMainFunction = library.makeFunction(name: "vertex_main")

        let fillPipelineDescriptor = MTLRenderPipelineDescriptor()
        fillPipelineDescriptor.vertexFunction = vertexBasicFunction
        fillPipelineDescriptor.fragmentFunction = fragmentFunction
        fillPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        let mainPipelineDescriptor = MTLRenderPipelineDescriptor()
        mainPipelineDescriptor.vertexFunction = vertexMainFunction
        mainPipelineDescriptor.fragmentFunction = fragmentFunction
        mainPipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

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

        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride * 2 + MemoryLayout<SIMD4<Float>>.stride

        mainPipelineDescriptor.vertexDescriptor = vertexDescriptor

        do {
            fillPipelineState = try device.makeRenderPipelineState(descriptor: fillPipelineDescriptor)
            mainPipelineState = try device.makeRenderPipelineState(descriptor: mainPipelineDescriptor)
       } catch {
           fatalError("Failed to create pipeline state: \(error)")
       }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Resize logic goes here if needed
    }

    func draw(in view: MTKView) {
        for words in enqueuedWords {
            let command = parseCommand(command: (words[0] >> 24) & 0x3f)

            print("got command \(command)")

            executeCommand(command: command, words: words)
        }

        enqueuedWords = []

        let screenWidth: Float = 320
        let screenHeight: Float = 240

        if canRender {
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPass = view.currentRenderPassDescriptor,
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPass) else {
                return
            }

            for rect in fillRects {
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

            if triangleProps.count > 0 {
                for i in 0...triangleProps.count - 1 {
                    let triangle = triangleProps[i]

                    var rdpVertices = [
                        RDPVertex(),
                        RDPVertex(),
                        RDPVertex()
                    ]

                    print("vertices = (\(triangle.xl), \(triangle.yl)), (\(triangle.xm), \(triangle.ym)), (\(triangle.xh), \(triangle.yh))")

                    let vertices = [
                        SIMD2<Float>((Float(triangle.xl) / screenWidth) * 2.0 - 1.0, (Float(triangle.yl) / screenHeight) * 2.0 - 1.0),
                        SIMD2<Float>((Float(triangle.xm) / screenWidth) * 2.0 - 1.0, (Float(triangle.ym) / screenHeight) * 2.0 - 1.0),
                        SIMD2<Float>((Float(triangle.xh) / screenWidth) * 2.0 - 1.0, (Float(triangle.yh) / screenHeight) * 2.0 - 1.0),
                    ]

                    rdpVertices[0].position = vertices[0]
                    rdpVertices[1].position = vertices[1]
                    rdpVertices[2].position = vertices[2]

                    let baseX = triangle.xl
                    let baseY = triangle.yl

                    if i < colorProps.count {
                        let color = colorProps[i]

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

                        let color0 = simd_clamp(SIMD4<Float>(Float(r0) / 65536.0 / 255.0, Float(g0) / 65536.0 / 255.0, Float(b0) / 65536.0 / 255.0, Float(a0) / 65536.0 / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
                        let color1 = simd_clamp(SIMD4<Float>(Float(r1) / 65536.0 / 255.0, Float(g1) / 65536.0 / 255.0, Float(b1) / 65536.0 / 255.0, Float(a1) / 65536.0 / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))
                        let color2 = simd_clamp(SIMD4<Float>(Float(r2) / 65536.0 / 255.0, Float(g2) / 65536.0 / 255.0, Float(b2) / 65536.0 / 255.0, Float(a2) / 65536.0 / 255.0), SIMD4<Float>(0.0, 0.0, 0.0, 0.0), SIMD4<Float>(1.0, 1.0, 1.0, 1.0))

                        rdpVertices[0].color = color0
                        rdpVertices[1].color = color1
                        rdpVertices[2].color = color2

                        for vertex in rdpVertices {
                            print(vertex.color)
                        }
                    }

                    let textureWidth: Float = 64
                    let textureHeight: Float = 64

                    if i < textureProps.count {
                        let texture = textureProps[i]

                        let u0 = texture.s
                        let v0 = texture.t

                        let u1 = u0 + texture.dsdx * (triangle.xm - baseX) + texture.dsdy * (triangle.ym - baseY)
                        let u2 = u0 + texture.dsdx * (triangle.xh - baseX) + texture.dsdy * (triangle.yh - baseY)

                        let v1 = v0 + texture.dtdx * (triangle.xm - baseX) + texture.dtdy * (triangle.ym - baseY)
                        let v2 = v0 + texture.dtdx * (triangle.xh - baseX) + texture.dtdy * (triangle.yh - baseY)

                        let uv0 = SIMD2<Float>(Float(u0) / (65536.0 * textureWidth), Float(v0) / (65536.0 * textureHeight))
                        let uv1 = SIMD2<Float>(Float(u1) / (65536.0 * textureWidth), Float(v1) / (65536.0 * textureHeight))
                        let uv2 = SIMD2<Float>(Float(u2) / (65536.0 * textureWidth), Float(v2) / (65536.0 * textureHeight))

                        rdpVertices[0].uv = uv0
                        rdpVertices[1].uv = uv1
                        rdpVertices[2].uv = uv2

                        for vertex in rdpVertices {
                            print(vertex.uv)
                        }
                    }

                    let vertexBuffer = device.makeBuffer(
                        bytes: rdpVertices,
                        length: MemoryLayout<RDPVertex>.stride * vertices.count,
                        options: []
                    )

                    encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                    encoder.setRenderPipelineState(mainPipelineState)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
            }

            encoder.endEncoding()
            commandBuffer.present(view.currentDrawable!)
            commandBuffer.commit()

            fillRects = []
            colorProps = []
            textureProps = []
            zProps = []
            triangleProps = []
            canRender = false
        }
    }

    func parseCommand(command: UInt32) -> RdpCommand {
        return RdpCommand(rawValue: command) ?? .Nop
    }

    func fillRectangle(words: [UInt32]) {
        var fillRect = FillRect()

        let word0 = words[0]
        let word1 = words[1]

        fillRect.x1 = ((word0 >> 12) & 0xFFF) >> 2
        fillRect.y1 = ((word0 >> 0) & 0xFFF) >> 2
        fillRect.x2 = ((word1 >> 12) & 0xFFF) >> 2
        fillRect.y2 = ((word1 >> 0) & 0xFFF) >> 2
        fillRect.color = fillColor

        canRender = true

        fillRects.append(fillRect)
    }

    func shadeTextureZBufferTriangle(words: [UInt32]) {
        var props = TriangleProps()
        props.flip = (words[0] >> 23) & 0b1 == 1

        let signDxhdy = (words[5] >> 31) & 0b1 == 1

        props.doOffset = props.flip == signDxhdy

        props.tile = (words[0] >> 16) & 0x3f

        props.yl = Float(signExtend(value: (words[0] & 0x3fff), bits: 14)) / 4.0
        props.ym = Float(signExtend(value: ((words[1] >> 16) & 0x3fff), bits: 14)) / 4.0
        props.yh = Float(signExtend(value: (words[1] & 0x3fff), bits: 14)) / 4.0

        props.xl = Float(signExtend(value: words[2] & 0xfffffff, bits: 28) >> 1) / 65536
        props.xm = Float(signExtend(value: words[6] & 0xfffffff, bits: 28) >> 1) / 65536
        props.xh = Float(signExtend(value: words[4] & 0xfffffff, bits: 28) >> 1) / 65536

        props.dxldy = Float(signExtend(value: (words[3] >> 2) & 0xfffffff, bits: 28) >> 1) / 65536
        props.dxmdy = Float(signExtend(value: (words[7] >> 2) & 0xfffffff, bits: 28) >> 1) / 65536
        props.dxhdy = Float(signExtend(value: (words[5] >> 2) & 0xfffffff, bits: 28) >> 1) / 65536

        triangleProps.append(props)

        var color = ColorProps()

        let r = (words[8] & 0xffff0000) | ((words[12] >> 16) & 0xffff)
        let g = (words[8] << 16) | (words[12] & 0xffff)
        let b = (words[9] & 0xffff0000) | ((words[13] >> 16) & 0xffff)
        let a = (words[9] << 16) | (words[13] & 0xffff)

        let drdx = (words[10] & 0xffff0000) | ((words[15] >> 16) & 0xffff)
        let dgdx = (words[10] << 16) | (words[14] & 0xffff)
        let dbdx = (words[11] & 0xffff0000) | ((words[15] >> 16) & 0xffff)
        let dadx = (words[11] << 16) | (words[15] & 0xffff)

        let drde = (words[16] & 0xffff0000) | ((words[20] >> 16) & 0xffff)
        let dgde = (words[16] << 16) | (words[20] & 0xffff)
        let dbde = (words[17] & 0xffff0000) | ((words[21] >> 16) & 0xffff)
        let dade = (words[17] << 16) | (words[21] & 0xffff)

        let drdy = (words[18] & 0xffff0000) | ((words[22] >> 16) & 0xffff)
        let dgdy = (words[18] << 16) | (words[22] & 0xffff)
        let dbdy = (words[19] & 0xffff0000) | ((words[23] >> 16) & 0xffff)
        let dady = (words[19] << 16) | (words[23] & 0xffff)

        color.r = Float(Int32(bitPattern: r))
        color.g = Float(Int32(bitPattern: g))
        color.b = Float(Int32(bitPattern: b))
        color.a = Float(Int32(bitPattern: a))

        color.drdx = Float(Int32(bitPattern: drdx))
        color.dgdx = Float(Int32(bitPattern: dgdx))
        color.dbdx = Float(Int32(bitPattern: dbdx))
        color.dadx = Float(Int32(bitPattern: dadx))

        color.drdy = Float(Int32(bitPattern: drdy))
        color.dgdy = Float(Int32(bitPattern: dgdy))
        color.dbdy = Float(Int32(bitPattern: dbdy))
        color.dady = Float(Int32(bitPattern: dady))

        color.drde = Float(Int32(bitPattern: drde))
        color.dgde = Float(Int32(bitPattern: dgde))
        color.dbde = Float(Int32(bitPattern: dbde))
        color.dade = Float(Int32(bitPattern: dade))

        colorProps.append(color)

        var texture = TextureProps()

        let s = ((words[24] & 0xffff0000) | ((words[28] >> 16) & 0xffff))
        let t = ((words[24] << 16) & 0xffff0000) | (words[28] & 0xffff)
        let w = (words[25] & 0xffff0000) | ((words[29] >> 16) & 0xffff)

        let dsdx = (words[26] & 0xffff0000) | ((words[30] >> 16) & 0xffff)
        let dtdx = ((words[26] << 16) & 0xffff0000) | (words[30] & 0xffff)

        print(dtdx)

        let dwdx = (words[27] & 0xffff0000) | ((words[31] >> 16) & 0xffff)

        let dsde = (words[32] & 0xffff0000) | ((words[36] >> 16) & 0xffff)
        let dtde = ((words[32] << 16) & 0xffff0000) | (words[36] & 0xffff)
        let dwde = (words[33] & 0xffff0000) | ((words[37] >> 16) & 0xffff)

        let dsdy = (words[34] & 0xffff0000) | ((words[38] >> 16) & 0xffff)
        let dtdy = ((words[34] << 16) & 0xffff0000) | (words[38] & 0xffff)
        let dwdy = (words[35] & 0xffff0000) | ((words[39] >> 16) & 0xffff)

        texture.s = Float(Int32(bitPattern: s))
        texture.t = Float(Int32(bitPattern: t))
        texture.w = Float(Int32(bitPattern: w))

        print("s = \(texture.s) t = \(texture.t) w = \(texture.w)")

        texture.dsdx = Float(Int32(bitPattern: dsdx))
        texture.dtdx = Float(Int32(bitPattern: dtdx))

        texture.dwdx = Float(Int32(bitPattern: dwdx))

        texture.dsde = Float(Int32(bitPattern: dsde))
        texture.dtde = Float(Int32(bitPattern: dtde))
        texture.dwde = Float(Int32(bitPattern: dwde))

        texture.dsdy = Float(Int32(bitPattern: dsdy))
        texture.dtdy = Float(Int32(bitPattern: dtdy))
        texture.dwdy = Float(Int32(bitPattern: dwdy))

        print(texture)

        textureProps.append(texture)

        var z = ZProps()

        z.z = Float(Int32(bitPattern: words[40]))
        z.dzdx = Float(Int32(bitPattern: words[41]))
        z.dzde = Float(Int32(bitPattern: words[42]))
        z.dzdy = Float(Int32(bitPattern: words[43]))

        zProps.append(z)

        canRender = true
    }

    func signExtend(value: UInt32, bits: Int) -> Int32 {
        let shift = 32 - bits

        let signed = Int32(bitPattern: value) << shift

        return signed >> shift
    }

    func setFillColor(words: [UInt32]) {
        fillColor = words[0]
    }

    func executeCommand(command: RdpCommand, words: [UInt32]) {
        switch command {
        case .Nop: break // do nothing
        case .MetaSignalTimeline: break
        case .MetaFlush: break
        case .MetaIdle: break
        case .MetaSetQuirks: break
        case .FillTriangle: break
        case .FillZBufferTriangle: break
        case .TextureTriangle: break
        case .TextureZBufferTriangle: break
        case .ShadeTriangle: break
        case .ShadeZBufferTriangle: break
        case .ShadeTextureTriangle: break
        case .ShadeTextureZBufferTriangle: shadeTextureZBufferTriangle(words: words)
        case .TextureRectangle: break
        case .TextureRectangleFlip: break
        case .SyncLoad: break
        case .SyncPipe: break
        case .SyncTile: break
        case .SyncFull: break
        case .SetKeyGB: break
        case .SetKeyR: break
        case .SetConvert: break
        case .SetScissor: break
        case .SetPrimDepth: break
        case .SetOtherModes: break
        case .LoadTLut: break
        case .SetTileSize: break
        case .LoadBlock: break
        case .LoadTile: break
        case .SetTile: break
        case .FillRectangle: fillRectangle(words: words)
        case .SetFillColor: setFillColor(words: words)
        case .SetFogColor: break
        case .SetBlendColor: break
        case .SetPrimColor: break
        case .SetEnvColor: break
        case .SetCombine: break
        case .SetTextureImage: break
        case .SetMaskImage: break
        case .SetColorImage: break
        }
    }
}
