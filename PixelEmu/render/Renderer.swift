//
//  Renderer.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/4/25.
//

import Metal
import MetalKit

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

    var enqueuedWords: [[UInt32]] = []

    init(mtkView: MTKView, enqueuedWords: [[UInt32]]) {
        self.device = mtkView.device!
        self.commandQueue = device.makeCommandQueue()!
        self.enqueuedWords = enqueuedWords
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Resize logic goes here if needed
    }

    func draw(in view: MTKView) {
        for words in enqueuedWords {
            let command = parseCommand(command: (words[0] >> 24) & 0x3f)

            executeCommand(command: command)
        }
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

    func parseCommand(command: UInt32) -> RdpCommand {
        print("rawValue = \(String(format: "%x", command))")
        return RdpCommand(rawValue: command) ?? .Nop
    }

    func executeCommand(command: RdpCommand) {
        print("got command \(command)")
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
        case .FillRectangle: break
        case .SetFillColor: break
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
