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

    var pipelineState: MTLRenderPipelineState!

    var enqueuedWords: [[UInt32]] = []

    var fillColor: UInt32 = 0
    var fillRects: [FillRect] = []

    init(mtkView: MTKView, enqueuedWords: [[UInt32]]) {
        self.device = mtkView.device!
        self.commandQueue = device.makeCommandQueue()!
        self.enqueuedWords = enqueuedWords
        super.init()

        let library = device.makeDefaultLibrary()!
        let vertexFunction = library.makeFunction(name: "vertex_main")!
        let fragmentFunction = library.makeFunction(name: "fragment_main")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat

        do {
           pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
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

            print("got command 0x\(String(format: "%x", (words[0] >> 24) & 0x3f))")

            executeCommand(command: command, words: words)
        }

        enqueuedWords = []
        print("finished with enqueued words")

        let screenWidth: Float = 320
        let screenHeight: Float = 240

        if (fillRects.count > 0) {
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

                print("x1 = \(x1) x2 = \(x2) y1 = \(y1) y2 = \(y2)")

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

                print("fx1 = \(fx1) fx2 = \(fx2) fy1 = \(fy1) fy2 = \(fy2)")

                var color = SIMD4<Float>(Float((rect.color >> 11) & 0x1f) / 31.0, Float((rect.color >> 6) & 0x1f) / 31.0, Float((rect.color >> 1) & 0x1f) / 31.0, Float((rect.color) & 1))

                let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<SIMD2<Float>>.stride, options: [])

                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)

                encoder.setRenderPipelineState(pipelineState)
                encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            }

            encoder.endEncoding()
            commandBuffer.present(view.currentDrawable!)
            commandBuffer.commit()

            fillRects = []
        }
    }

    func drawSolidRect(vertices: [SIMD2<Float>], color: SIMD4<Float>, in view: MTKView) {

    }

    func parseCommand(command: UInt32) -> RdpCommand {
        return RdpCommand(rawValue: command) ?? .Nop
    }

    func fillRectangle(words: [UInt32]) {
        var fillRect = FillRect()

        let word0 = words[0]
        let word1 = words[1]

        print("got words \(String(format: "%x", word0)) and \(String(format: "%x", word1))" )

        fillRect.x1 = ((word0 >> 12) & 0xFFF) >> 2
        fillRect.y1 = ((word0 >> 0) & 0xFFF) >> 2
        fillRect.x2 = ((word1 >> 12) & 0xFFF) >> 2
        fillRect.y2 = ((word1 >> 0) & 0xFFF) >> 2
        fillRect.color = fillColor

        fillRects.append(fillRect)
    }



    func setFillColor(words: [UInt32]) {
        fillColor = words[0]
    }

    func executeCommand(command: RdpCommand, words: [UInt32]) {
        // print("got command \(command)")
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
        case .ShadeTextureZBufferTriangle: break
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
