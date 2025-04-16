//
//  N64GameView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/1/25.
//

import SwiftUI
import MetalKit

let SRAM_SIZE = 0x8000
let FLASH_SIZE = 0x20000
let EEPROM_SIZE = 0x800
let MEMPAK_SIZE = 0x8000

let SRAM_TYPE: Int32 = 0
let FLASH_TYPE: Int32 = 1
let EEPROM4K_TYPE: Int32 = 2
let EEPROM16K_TYPE: Int32 = 3
let MEMPAK_TYPE: Int32 = 4

let MAX_TEXELS: UInt32 = 2048

enum CycleType {
    case cycle1
}

struct FragmentUniforms {
    var hasTexture = false
    var clampS = false
    var clampT = false
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

    var texture: MTLTexture? = nil
    var validHeight: Int = 0
}

struct TexImageProps {
    var address: UInt32 = 0
    var width: UInt32 = 0
    var size: TextureSize = .Bpp4
    var format: TextureFormat = .RGBA
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

struct TileState {
    var slo: UInt32 = 0
    var shi: UInt32 = 0
    var tlo: UInt32 = 0
    var thi: UInt32 = 0
    var tileProps = TileProps()
    var texture: MTLTexture? = nil
    var textures: [MTLTexture?] = []
    var validHeight: Int = 0
}

struct TileProps {
    var mirrorSBit = false
    var clampSBit = false
    var mirrorTBit = false
    var clampTBit = false

    var offset: UInt32 = 0
    var stride: UInt32 = 0
    var size: TextureSize = .Bpp4
    var fmt: TextureFormat = .RGBA
    var palette: UInt32 = 0

    var shiftS: UInt32 = 0
    var shiftT: UInt32 = 0
    var maskS: UInt32 = 0
    var maskT: UInt32 = 0
}

struct RDPVertex {
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
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

enum TextureSize: UInt8 {
    case Bpp4 = 0
    case Bpp8 = 1
    case Bpp16 = 2
    case Bpp32 = 3
}

enum TextureFormat: UInt8
{
    case RGBA = 0
    case YUV = 1
    case CI = 2
    case IA = 3
    case I = 4
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

struct TexturedVertex {
    var position: SIMD2<Float>
    var uv: SIMD2<Float>
}

var rendererState = RendererState()

struct N64GameView: View {
    @Binding var romData: Data?
    @Binding var gameUrl: URL?
    @Binding var themeColor: Color
    
    @State private var backupFiles: [BackupFile] = []
    @State private var enqueuedWords: [[UInt32]] = []
    @State private var mtkView: MTKView? = nil
    @State private var device: MTLDevice? = nil

    @State private var tmem = [UInt8](repeating: 0, count: 4096)

    @State private var rdpState = RDPState()
    @State private var fillColor: UInt32 = 0
    @State private var textureImage = TexImageProps()

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

        rendererState.canRender = true

        rendererState.fillRects.append(fillRect)
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

        props.xl = Float(signExtend(value: words[2] & 0xfffffff, bits: 28)) / 65536.0
        props.xm = Float(signExtend(value: words[6] & 0xfffffff, bits: 28)) / 65536.0
        props.xh = Float(signExtend(value: words[4] & 0xfffffff, bits: 28)) / 65536.0

        props.dxldy = Float(signExtend(value: (words[3] >> 2) & 0xfffffff, bits: 28)) / 65536.0
        props.dxmdy = Float(signExtend(value: (words[7] >> 2) & 0xfffffff, bits: 28)) / 65536.0
        props.dxhdy = Float(signExtend(value: (words[5] >> 2) & 0xfffffff, bits: 28)) / 65536.0


        if rendererState.tiles[rendererState.currentTile].texture == nil {
            let tileWidth = rendererState.tiles[rendererState.currentTile].shi - rendererState.tiles[rendererState.currentTile].slo + 1
            let tileHeight = rendererState.tiles[rendererState.currentTile].thi - rendererState.tiles[rendererState.currentTile].tlo + 1
            rendererState.tiles[rendererState.currentTile].texture = decodeRDRAMTexture(address: rendererState.vramAddress, width: Int(tileWidth), height: Int(tileHeight))
            // rendererState.tiles[rendererState.currentTile].texture = decodeRGBA16(tile: rendererState.tiles[rendererState.currentTile])
            rendererState.blockTexelsLoaded = 0
        }

        props.texture = rendererState.tiles[rendererState.currentTile].texture
        props.validHeight = rendererState.tiles[rendererState.currentTile].validHeight

        // props.texture = decodeRGBA16(tile: rendererState.tiles[rendererState.currentTile], dataTile: rendererState.tiles[7])

        rendererState.triangleProps.append(props)

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

        color.r = Float(Int32(bitPattern: r)) / 65536.0
        color.g = Float(Int32(bitPattern: g)) / 65536.0
        color.b = Float(Int32(bitPattern: b)) / 65536.0
        color.a = Float(Int32(bitPattern: a)) / 65536.0

        color.drdx = Float(Int32(bitPattern: drdx)) / 65536.0
        color.dgdx = Float(Int32(bitPattern: dgdx)) / 65536.0
        color.dbdx = Float(Int32(bitPattern: dbdx)) / 65536.0
        color.dadx = Float(Int32(bitPattern: dadx)) / 65536.0

        color.drdy = Float(Int32(bitPattern: drdy)) / 65536.0
        color.dgdy = Float(Int32(bitPattern: dgdy)) / 65536.0
        color.dbdy = Float(Int32(bitPattern: dbdy)) / 65536.0
        color.dady = Float(Int32(bitPattern: dady)) / 65536.0

        color.drde = Float(Int32(bitPattern: drde)) / 65536.0
        color.dgde = Float(Int32(bitPattern: dgde)) / 65536.0
        color.dbde = Float(Int32(bitPattern: dbde)) / 65536.0
        color.dade = Float(Int32(bitPattern: dade)) / 65536.0

        rendererState.colorProps.append(color)

        var texture = TextureProps()

        let s = ((words[24] & 0xffff0000) | ((words[28] >> 16) & 0xffff))
        let t = ((words[24] << 16) & 0xffff0000) | (words[28] & 0xffff)
        let w = (words[25] & 0xffff0000) | ((words[29] >> 16) & 0xffff)

        let dsdx = (words[26] & 0xffff0000) | ((words[30] >> 16) & 0xffff)
        let dtdx = ((words[26] << 16) & 0xffff0000) | (words[30] & 0xffff)

        let dwdx = (words[27] & 0xffff0000) | ((words[31] >> 16) & 0xffff)

        let dsde = (words[32] & 0xffff0000) | ((words[36] >> 16) & 0xffff)
        let dtde = ((words[32] << 16) & 0xffff0000) | (words[36] & 0xffff)
        let dwde = (words[33] & 0xffff0000) | ((words[37] >> 16) & 0xffff)

        let dsdy = (words[34] & 0xffff0000) | ((words[38] >> 16) & 0xffff)
        let dtdy = ((words[34] << 16) & 0xffff0000) | (words[38] & 0xffff)
        let dwdy = (words[35] & 0xffff0000) | ((words[39] >> 16) & 0xffff)

        texture.s = Float(Int32(bitPattern: s)) / 65536.0
        texture.t = Float(Int32(bitPattern: t)) / 65536.0
        texture.w = Float(Int32(bitPattern: w)) / 65536.0

        texture.dsdx = Float(Int32(bitPattern: dsdx)) / 65536.0
        texture.dtdx = Float(Int32(bitPattern: dtdx)) / 65536.0

        texture.dwdx = Float(Int32(bitPattern: dwdx)) / 65536.0

        texture.dsde = Float(Int32(bitPattern: dsde)) / 65536.0
        texture.dtde = Float(Int32(bitPattern: dtde)) / 65536.0
        texture.dwde = Float(Int32(bitPattern: dwde)) / 65536.0

        texture.dsdy = Float(Int32(bitPattern: dsdy)) / 65536.0
        texture.dtdy = Float(Int32(bitPattern: dtdy)) / 65536.0
        texture.dwdy = Float(Int32(bitPattern: dwdy)) / 65536.0

        rendererState.textureProps.append(texture)

        var z = ZProps()

        z.z = Float(Int32(bitPattern: words[40])) / 65536.0
        z.dzdx = Float(Int32(bitPattern: words[41])) / 65536.0
        z.dzde = Float(Int32(bitPattern: words[42])) / 65536.0
        z.dzdy = Float(Int32(bitPattern: words[43])) / 65536.0

        rendererState.zProps.append(z)

        rendererState.canRender = true
    }

    func shadeZBufferTriangle(words: [UInt32]) {
        var props = TriangleProps()
        props.flip = (words[0] >> 23) & 0b1 == 1

        let signDxhdy = (words[5] >> 31) & 0b1 == 1

        props.doOffset = props.flip == signDxhdy

        props.tile = (words[0] >> 16) & 0x3f

        props.yl = Float(signExtend(value: (words[0] & 0x3fff), bits: 14)) / 4.0
        props.ym = Float(signExtend(value: ((words[1] >> 16) & 0x3fff), bits: 14)) / 4.0
        props.yh = Float(signExtend(value: (words[1] & 0x3fff), bits: 14)) / 4.0

        props.xl = Float(signExtend(value: words[2] & 0xfffffff, bits: 28)) / 65536.0
        props.xm = Float(signExtend(value: words[6] & 0xfffffff, bits: 28)) / 65536.0
        props.xh = Float(signExtend(value: words[4] & 0xfffffff, bits: 28)) / 65536.0

        props.dxldy = Float(signExtend(value: (words[3] >> 2) & 0xfffffff, bits: 28)) / 65536.0
        props.dxmdy = Float(signExtend(value: (words[7] >> 2) & 0xfffffff, bits: 28)) / 65536.0
        props.dxhdy = Float(signExtend(value: (words[5] >> 2) & 0xfffffff, bits: 28)) / 65536.0

        rendererState.triangleProps.append(props)

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

        color.r = Float(Int32(bitPattern: r)) / 65536.0
        color.g = Float(Int32(bitPattern: g)) / 65536.0
        color.b = Float(Int32(bitPattern: b)) / 65536.0
        color.a = Float(Int32(bitPattern: a)) / 65536.0

        color.drdx = Float(Int32(bitPattern: drdx)) / 65536.0
        color.dgdx = Float(Int32(bitPattern: dgdx)) / 65536.0
        color.dbdx = Float(Int32(bitPattern: dbdx)) / 65536.0
        color.dadx = Float(Int32(bitPattern: dadx)) / 65536.0

        color.drdy = Float(Int32(bitPattern: drdy)) / 65536.0
        color.dgdy = Float(Int32(bitPattern: dgdy)) / 65536.0
        color.dbdy = Float(Int32(bitPattern: dbdy)) / 65536.0
        color.dady = Float(Int32(bitPattern: dady)) / 65536.0

        color.drde = Float(Int32(bitPattern: drde)) / 65536.0
        color.dgde = Float(Int32(bitPattern: dgde)) / 65536.0
        color.dbde = Float(Int32(bitPattern: dbde)) / 65536.0
        color.dade = Float(Int32(bitPattern: dade)) / 65536.0

        rendererState.colorProps.append(color)

        rendererState.textureProps.append(nil)

        var z = ZProps()

        z.z = Float(Int32(bitPattern: words[24])) / 65536.0
        z.dzdx = Float(Int32(bitPattern: words[25])) / 65536.0
        z.dzde = Float(Int32(bitPattern: words[26])) / 65536.0
        z.dzdy = Float(Int32(bitPattern: words[27])) / 65536.0

        rendererState.zProps.append(z)
        rendererState.canRender = true
    }

    func shadeTextureTriangle(words: [UInt32]) {
        var props = TriangleProps()
        props.flip = (words[0] >> 23) & 0b1 == 1

        let signDxhdy = (words[5] >> 31) & 0b1 == 1

        props.doOffset = props.flip == signDxhdy

        props.tile = (words[0] >> 16) & 0x3f

        props.yl = Float(signExtend(value: (words[0] & 0x3fff), bits: 14)) / 4.0
        props.ym = Float(signExtend(value: ((words[1] >> 16) & 0x3fff), bits: 14)) / 4.0
        props.yh = Float(signExtend(value: (words[1] & 0x3fff), bits: 14)) / 4.0

        props.xl = Float(signExtend(value: words[2] & 0xfffffff, bits: 28)) / 65536.0
        props.xm = Float(signExtend(value: words[6] & 0xfffffff, bits: 28)) / 65536.0
        props.xh = Float(signExtend(value: words[4] & 0xfffffff, bits: 28)) / 65536.0

        props.dxldy = Float(signExtend(value: (words[3] >> 2) & 0xfffffff, bits: 28)) / 65536.0
        props.dxmdy = Float(signExtend(value: (words[7] >> 2) & 0xfffffff, bits: 28)) / 65536.0
        props.dxhdy = Float(signExtend(value: (words[5] >> 2) & 0xfffffff, bits: 28)) / 65536.0

//        print("area = \(area), xh = \(props.xh), xm = \(props.xm), xl = \(props.xl), yh = \(props.yh), ym = \(props.ym), yl = \(props.yl), dxhdy = \(props.dxhdy), dxmdy = \(props.dxmdy), dxldy = \(props.dxldy)")

        if rendererState.tiles[rendererState.currentTile].texture == nil {
            let tileWidth = rendererState.tiles[rendererState.currentTile].shi - rendererState.tiles[rendererState.currentTile].slo + 1
            let tileHeight = rendererState.tiles[rendererState.currentTile].thi - rendererState.tiles[rendererState.currentTile].tlo + 1
            rendererState.tiles[rendererState.currentTile].texture = decodeRDRAMTexture(address: rendererState.vramAddress, width: Int(tileWidth), height: Int(tileHeight))
            // rendererState.tiles[rendererState.currentTile].texture = decodeRGBA16(tile: rendererState.tiles[rendererState.currentTile])
            rendererState.blockTexelsLoaded = 0
        }

        props.texture = rendererState.tiles[rendererState.currentTile].texture
        props.validHeight = rendererState.tiles[rendererState.currentTile].validHeight

//        props.texture = decodeRGBA16(tile: rendererState.tiles[rendererState.currentTile], dataTile: rendererState.tiles[7])
//        rendererState.tiles[rendererState.currentTile].textures.append(decodeRGBA16(tile: rendererState.tiles[rendererState.currentTile], dataTile: rendererState.tiles[7]))

        rendererState.triangleProps.append(props)

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

        color.r = Float(Int32(bitPattern: r)) / 65536.0
        color.g = Float(Int32(bitPattern: g)) / 65536.0
        color.b = Float(Int32(bitPattern: b)) / 65536.0
        color.a = Float(Int32(bitPattern: a)) / 65536.0

        color.drdx = Float(Int32(bitPattern: drdx)) / 65536.0
        color.dgdx = Float(Int32(bitPattern: dgdx)) / 65536.0
        color.dbdx = Float(Int32(bitPattern: dbdx)) / 65536.0
        color.dadx = Float(Int32(bitPattern: dadx)) / 65536.0

        color.drdy = Float(Int32(bitPattern: drdy)) / 65536.0
        color.dgdy = Float(Int32(bitPattern: dgdy)) / 65536.0
        color.dbdy = Float(Int32(bitPattern: dbdy)) / 65536.0
        color.dady = Float(Int32(bitPattern: dady)) / 65536.0

        color.drde = Float(Int32(bitPattern: drde)) / 65536.0
        color.dgde = Float(Int32(bitPattern: dgde)) / 65536.0
        color.dbde = Float(Int32(bitPattern: dbde)) / 65536.0
        color.dade = Float(Int32(bitPattern: dade)) / 65536.0

        rendererState.colorProps.append(color)

        var texture = TextureProps()

        let s = ((words[24] & 0xffff0000) | ((words[28] >> 16) & 0xffff))
        let t = ((words[24] << 16) & 0xffff0000) | (words[28] & 0xffff)
        let w = (words[25] & 0xffff0000) | ((words[29] >> 16) & 0xffff)

        let dsdx = (words[26] & 0xffff0000) | ((words[30] >> 16) & 0xffff)
        let dtdx = ((words[26] << 16) & 0xffff0000) | (words[30] & 0xffff)

        let dwdx = (words[27] & 0xffff0000) | ((words[31] >> 16) & 0xffff)

        let dsde = (words[32] & 0xffff0000) | ((words[36] >> 16) & 0xffff)
        let dtde = ((words[32] << 16) & 0xffff0000) | (words[36] & 0xffff)
        let dwde = (words[33] & 0xffff0000) | ((words[37] >> 16) & 0xffff)

        let dsdy = (words[34] & 0xffff0000) | ((words[38] >> 16) & 0xffff)
        let dtdy = ((words[34] << 16) & 0xffff0000) | (words[38] & 0xffff)
        let dwdy = (words[35] & 0xffff0000) | ((words[39] >> 16) & 0xffff)

        texture.s = Float(Int32(bitPattern: s)) / 65536.0
        texture.t = Float(Int32(bitPattern: t)) / 65536.0
        texture.w = Float(Int32(bitPattern: w)) / 65536.0

        texture.dsdx = Float(Int32(bitPattern: dsdx)) / 65536.0
        texture.dtdx = Float(Int32(bitPattern: dtdx)) / 65536.0

        texture.dwdx = Float(Int32(bitPattern: dwdx)) / 65536.0

        texture.dsde = Float(Int32(bitPattern: dsde)) / 65536.0
        texture.dtde = Float(Int32(bitPattern: dtde)) / 65536.0
        texture.dwde = Float(Int32(bitPattern: dwde)) / 65536.0

        texture.dsdy = Float(Int32(bitPattern: dsdy)) / 65536.0
        texture.dtdy = Float(Int32(bitPattern: dtdy)) / 65536.0
        texture.dwdy = Float(Int32(bitPattern: dwdy)) / 65536.0

        rendererState.textureProps.append(texture)

        rendererState.zProps.append(nil)

        rendererState.zProps.append(nil)
        rendererState.canRender = true
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
        case .ShadeZBufferTriangle: shadeZBufferTriangle(words: words)
        case .ShadeTextureTriangle: shadeTextureTriangle(words: words)
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
        case .SetOtherModes: setOtherModes(words: words)
        case .LoadTLut: break
        case .SetTileSize: setTileSize(words: words)
        case .LoadBlock: loadBlock(words: words)
        case .LoadTile: loadTile(words: words)
        case .SetTile: setTile(words: words)
        case .FillRectangle: fillRectangle(words: words)
        case .SetFillColor: setFillColor(words: words)
        case .SetFogColor: break
        case .SetBlendColor: break
        case .SetPrimColor: break
        case .SetEnvColor: break
        case .SetCombine: break
        case .SetTextureImage: setTextureImage(words: words)
        case .SetMaskImage: break
        case .SetColorImage: break
        }
    }

    func loadTile(words: [UInt32]) {
        let tile = Int((words[1] >> 24) & 7)

        let address = textureImage.address
        let texWidth = textureImage.width
        let format = textureImage.format
        let size = textureImage.size

        let slo = ((words[0] >> 12) & 0xfff) >> 2
        let shi = ((words[1] >> 12) & 0xfff) >> 2
        let tlo = ((words[0] >> 0) & 0xfff) >> 2
        let thi = ((words[1] >> 0) & 0xfff) >> 2

        let width = shi - slo + 1
        let height = thi - tlo + 1

        var bytesPerPixel: UInt32 = 0

        switch size {
        case .Bpp16: bytesPerPixel = 2
        case .Bpp32: bytesPerPixel = 4
        case .Bpp8: bytesPerPixel = 1
        case .Bpp4: bytesPerPixel = 1
        }

        let byteLength = width * height * bytesPerPixel

        let rdramOffset = getRdramPtr(address)

        let data = UnsafeBufferPointer(start: rdramOffset, count: Int(byteLength))

        var i = 0

        var bytes: [UInt8] = []

        if format == .RGBA && size == .Bpp16 {
            while i < byteLength {
                let texel = UInt16(data[i + 1]) << 8 | UInt16(data[i])

                var r = UInt8((texel >> 11) & 0x1F)
                var g = UInt8((texel >> 6) & 0x1F)
                var b = UInt8((texel >> 1) & 0x1F)
                let a = UInt8((texel & 0b1) * 255)

                r = (r << 3) | (r >> 2)
                g = (g << 3) | (g >> 2)
                b = (b << 3) | (b >> 2)

                bytes.append(r)
                bytes.append(g)
                bytes.append(b)
                bytes.append(a)

                i += 2
            }
        } else {
            fatalError("texture size not supported yet: \(size)")
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(width),
            height: Int(height),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        let texture = device?.makeTexture(descriptor: descriptor)!

        texture?.replace(
            region: MTLRegionMake2D(0, 0, Int(width), Int(height)),
            mipmapLevel: 0,
            withBytes: bytes,
            bytesPerRow: Int(width) * 4
        )

        rendererState.currentTile = tile

        rendererState.tiles[tile].texture = texture
    }

    func signExtend(value: UInt32, bits: Int) -> Int32 {
        let shift = 32 - bits

        let signed = Int32(bitPattern: value) << shift

        return signed >> shift
    }

    func setFillColor(words: [UInt32]) {
        fillColor = words[0]
    }

    func setTextureImage(words: [UInt32]) {
        let format = TextureFormat(rawValue: UInt8((words[0] >> 21) & 7))!
        let size = TextureSize(rawValue: UInt8((words[0] >> 19) & 3))!

        let width = (words[0] & 0x3ff) + 1
        let address = words[1] & 0xffffff

        textureImage.address = address
        textureImage.width = width
        textureImage.size = size
        textureImage.format = format
    }

    func setTileSize(words: [UInt32]) {
        let tile = Int((words[1] >> 24) & 7)
        let slo = (words[0] >> 12) & 0xfff
        let shi = (words[1] >> 12) & 0xfff
        let tlo = words[0] & 0xfff
        let thi = words[1] & 0xfff

        rendererState.tiles[tile].slo = slo >> 2
        rendererState.tiles[tile].shi = shi >> 2
        rendererState.tiles[tile].tlo = tlo >> 2
        rendererState.tiles[tile].thi = thi >> 2

        rendererState.tiles[tile].texture = nil

        if rendererState.blockTexelsLoaded != 0 {
            let tileWidth = rendererState.tiles[tile].shi - rendererState.tiles[tile].slo + 1
            rendererState.tiles[tile].validHeight = rendererState.blockTexelsLoaded / Int(tileWidth)
            rendererState.blockTexelsLoaded = 0
        }


        // rendererState.tiles[tile].texture = decodeRGBA16(tile: rendererState.tiles[tile])
        // rendererState.tiles[tile].textures.append(decodeRGBA16(tile: rendererState.tiles[tile], dataTile: rendererState.tiles[7]))

        // print("setting rendererState.currentTile to \(tile)")
        rendererState.currentTile = tile
    }

    func setTile(words: [UInt32]) {
        let tile = Int((words[1] >> 24) & 7)

        var props = TileProps()

        props.offset = ((words[0] >> 0) & 511) << 3
        props.stride = ((words[0] >> 9) & 511) << 3
        props.size = TextureSize(rawValue: UInt8((words[0] >> 19) & 3))!
        props.fmt = TextureFormat(rawValue: UInt8((words[0] >> 21) & 7))!

        props.palette = (words[1] >> 20) & 15

        props.shiftS = (words[1] >> 0) & 15
        props.maskS = min((words[1] >> 4) & 15, 10)
        props.shiftT = (words[1] >> 10) & 15
        props.maskT = min((words[1] >> 14) & 15, 10)

        if (words[1] & (1 << 8) != 0) {
            props.mirrorSBit = true
        }
        if (words[1] & (1 << 9) != 0 || props.maskS == 0) {
            props.clampSBit = true
        }
        if (words[1] & (1 << 18) != 0) {
            props.mirrorTBit = true
        }
        if (words[1] & (1 << 19) != 0 || props.maskT == 0) {
            props.clampTBit = true
        }

        rendererState.tiles[tile].texture = nil
        rendererState.tiles[tile].tileProps = props
    }

    func setOtherModes(words: [UInt32]) {
        if (words[0] >> 19) & 0b1 == 1 {

        }
    }

    func loadBlock(words: [UInt32]) {
        let tile = Int((words[1] >> 24) & 7)

        let address = textureImage.address
        let width = textureImage.width
        let format = textureImage.format
        let size = textureImage.size

        let slo = ((words[0] >> 12) & 0xfff) >> 2
        let shi = ((words[1] >> 12) & 0xfff) >> 2
        let tlo = ((words[0] >> 0) & 0xfff) >> 2
        let dt = ((words[1] >> 0) & 0xfff) >> 2

        let numTexels = shi - slo + 1


        rendererState.blockTexelsLoaded += Int(numTexels)

        for i in 0..<8 {
            rendererState.tiles[i].texture = nil
            let tileWidth = rendererState.tiles[i].shi - rendererState.tiles[i].slo + 1
            rendererState.tiles[i].validHeight = rendererState.blockTexelsLoaded / Int(tileWidth)
        }

        if numTexels > MAX_TEXELS {
            return
        }

        var bytesPerPixel: UInt32 = 0

        switch size {
        case .Bpp16: bytesPerPixel = 2
        case .Bpp32: bytesPerPixel = 4
        case .Bpp8: bytesPerPixel = 1
        case .Bpp4: bytesPerPixel = 0
        }

        let byteCount = numTexels * bytesPerPixel

        let vramAddress = address + ((width * tlo + slo) << (size.rawValue - 1))

        let rdramOffset = getRdramPtr(vramAddress)
        let data = UnsafeBufferPointer(start: rdramOffset, count: Int(byteCount + 7))

        // Assuming RGBA16 for now
        if format == .RGBA && size == .Bpp16 {
            let qWords = (byteCount + 7) >> 3
            if dt == 0 {
                var ramOffset = 0
                var tmemOffset = Int(rendererState.tiles[tile].tileProps.offset)
                for _ in 0..<qWords {
                    for i in 0..<8 {
                        tmem[tmemOffset + i] = data[ramOffset + (i ^ 1)]
                    }
                    tmemOffset += 8
                    ramOffset += 8
                }
            } else {
                let wordSwapBit = 1

                var ramOffset = 0
                var tmemOffset = Int(rendererState.tiles[tile].tileProps.offset)
                let qWordsPerLine = (2048 / dt)

                var oddRow = false

                var i = 0

                while i < qWords {
                    let qWordsToCopy = min(Int(qWords) - i, Int(qWordsPerLine))

                    if oddRow {
                        for _ in 0..<qWordsToCopy {
                            for j in 0..<8 {
                                let swizzledIndex = j ^ 4
                                tmem[tmemOffset + swizzledIndex] = data[(ramOffset + j) ^ 3]
                            }
                            tmemOffset += 8
                            ramOffset += 8
                        }
                    } else {
                        for _ in 0..<qWordsToCopy {
                            for j in 0..<8 {
                                tmem[tmemOffset + j] = data[(ramOffset + j) ^ 3]
                            }
                            tmemOffset += 8
                            ramOffset += 8
                        }
                    }

                    i += qWordsToCopy

                    oddRow = !oddRow
                }
            }
        } else {
            // fatalError("pixel format not supported yet: \(format) \(size)")
        }
        rendererState.vramAddress = vramAddress
    }

    func decodeTmem(_ width: Int, _ numTexels: Int) -> MTLTexture? {
        var bytes: [UInt8] = []

        let textureWidth = 32
        let textureHeight = numTexels / 32

        let bytesPerTexel = 2
        let byteCount = textureWidth * textureHeight * bytesPerTexel

        for i in stride(from: 0, to: byteCount, by: 2) {
            let texel = UInt16(tmem[i]) << 8 | UInt16(tmem[i + 1])

            var r = UInt8((texel >> 11) & 0x1F)
            var g = UInt8((texel >> 6) & 0x1F)
            var b = UInt8((texel >> 1) & 0x1F)
            let a = UInt8((texel & 0b1) * 0xff)

            r = (r << 3) | (r >> 2)
            g = (g << 3) | (g >> 2)
            b = (b << 3) | (b >> 2)

            bytes.append(r)
            bytes.append(g)
            bytes.append(b)
            bytes.append(a)
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: textureWidth,
            height: textureHeight,
            mipmapped: false
        )

        descriptor.usage = [.shaderRead]
        guard let texture = device?.makeTexture(descriptor: descriptor) else { return nil }

        texture.replace(
            region: MTLRegionMake2D(0, 0, textureWidth, textureHeight),
            mipmapLevel: 0,
            withBytes: bytes,
            bytesPerRow: 32 * 4
        )

        return texture
    }

    func decodeRDRAMTexture(address: UInt32, width: Int, height: Int) -> MTLTexture? {
        let bytesPerTexel = 2 // assuming RGBA16 for now
        let byteCount = width * height * bytesPerTexel

        let rdramPtr = getRdramPtr(address)
        let data = UnsafeBufferPointer(start: rdramPtr, count: byteCount)

        var bytes: [UInt8] = []

        for i in stride(from: 0, to: byteCount, by: 2) {
            let texel = UInt16(data[i + 1]) << 8 | UInt16(data[i])

            var r = UInt8((texel >> 11) & 0x1F)
            var g = UInt8((texel >> 6) & 0x1F)
            var b = UInt8((texel >> 1) & 0x1F)
            let a = UInt8((texel & 0b1) * 0xff)

            r = (r << 3) | (r >> 2)
            g = (g << 3) | (g >> 2)
            b = (b << 3) | (b >> 2)

            bytes.append(r)
            bytes.append(g)
            bytes.append(b)
            bytes.append(a)
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )

        descriptor.usage = [.shaderRead]
        guard let texture = device?.makeTexture(descriptor: descriptor) else { return nil }

        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: bytes,
            bytesPerRow: width * 4
        )

        return texture
    }

    func decodeRGBA16(tile: TileState) -> MTLTexture? {
        let tileWidth = tile.shi - tile.slo + 1
        let tileHeight = min(Int(tile.thi - tile.tlo) + 1, tile.validHeight)

        let srcRowStride = tile.tileProps.stride
        var srcRowOffset = tile.tileProps.offset

        var bytes = [UInt8]()

        var rowSwizzle: UInt32 = 0
        for y in 0..<tileHeight {
            var srcOffset = srcRowOffset
            for x in 0..<tileWidth {
                let index = Int(srcOffset ^ rowSwizzle)

                let texel = UInt16(tmem[index]) << 8 | UInt16(tmem[index + 1])

                var r = UInt8((texel >> 11) & 0x1F)
                var g = UInt8((texel >> 6) & 0x1F)
                var b = UInt8((texel >> 1) & 0x1F)
                let a = UInt8((texel & 0b1) * 0xff)

                r = (r << 3) | (r >> 2)
                g = (g << 3) | (g >> 2)
                b = (b << 3) | (b >> 2)

                bytes.append(r)
                bytes.append(g)
                bytes.append(b)
                bytes.append(a)

                srcOffset += 2
            }
            srcRowOffset += srcRowStride

            rowSwizzle ^= 4
        }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(tileWidth),
            height: Int(tileHeight),
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        let texture = device?.makeTexture(descriptor: descriptor)!

        texture?.replace(
            region: MTLRegionMake2D(0, 0, Int(tileWidth), Int(tileHeight)),
            mipmapLevel: 0,
            withBytes: bytes,
            bytesPerRow: Int(tileWidth) * 4
        )

        return texture
    }

    var body: some View {
        if gameUrl != nil {
            ZStack {
                themeColor
                VStack {
                    MetalView(rendererState: rendererState) { (mtkView, device) in
                        if (self.mtkView == nil && self.device == nil) {
                            DispatchQueue.main.async {
                                self.mtkView = mtkView
                                self.device = device
                            }
                        }
                    }
                        .frame(width: 320, height: 240)
                        .padding(.top, 75)
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
            .edgesIgnoringSafeArea(.all)
            .statusBarHidden()
            .onAppear {
                guard let romData = romData else {
                    print("No ROM data!")
                    return
                }

                var data = Array(romData)

                let romSize = UInt32(data.count)

                data.withUnsafeMutableBufferPointer { ptr in
                    initEmulator(ptr.baseAddress!, romSize)
                }

                backupFiles = []
                let ptr = getSaveTypes()
                let count = getSaveTypesSize()

                let buffer = UnsafeBufferPointer(start: ptr, count: Int(count))

                let saveTypes = Array(buffer)

                for type in saveTypes {
                    switch (type) {
                    case SRAM_TYPE:
                        backupFiles.append(BackupFile(capacity: SRAM_SIZE, gameUrl: gameUrl!))
                    case FLASH_TYPE:
                        backupFiles.append(BackupFile(capacity: FLASH_SIZE, gameUrl: gameUrl!))
                    case EEPROM4K_TYPE:
                        backupFiles.append(BackupFile(capacity: EEPROM_SIZE, gameUrl: gameUrl!))
                    case EEPROM16K_TYPE:
                        backupFiles.append(BackupFile(capacity: EEPROM_SIZE, gameUrl: gameUrl!))
                    case MEMPAK_TYPE:
                        backupFiles.append(BackupFile(capacity: MEMPAK_SIZE, gameUrl: gameUrl!))
                    default:
                        print("invalid backup file specified")
                    }
                }

                DispatchQueue.global().async {
                    while true {
                        DispatchQueue.main.sync {
                            while (!getFrameFinished()) {
                                step()
                                
                                if (getCmdsReady()) {
                                    let wordPtr = getFlattened()
                                    let lengthPtr = getRowLengths()
                                    let numRows = getNumRows()
                                    let totalWordCount = getWordCount()
                                    
                                    let wordBuffer = UnsafeBufferPointer(start: wordPtr, count: Int(totalWordCount))
                                    let rowLengths = UnsafeBufferPointer(start: lengthPtr, count: Int(numRows))
                                    
                                    var cursor = 0
                                    for rowLen in rowLengths {
                                        let row = Array(wordBuffer[cursor ..< cursor + Int(rowLen)])
                                        enqueuedWords.append(row)
                                        cursor += Int(rowLen)
                                    }

                                    for words in enqueuedWords {
                                        let command = parseCommand(command: (words[0] >> 24) & 0x3f)
                                        executeCommand(command: command, words: words)
                                    }

                                    enqueuedWords = []
                                    clearCmdsReady()
                                    clearEnqueuedCommands()


                                }
                            }

                            limitFps()
                            clearFrameFinished()

                            if rendererState.canRender {
                                mtkView?.draw()
                            }
                        }
                    }
                }
            }
        }
    }
}
