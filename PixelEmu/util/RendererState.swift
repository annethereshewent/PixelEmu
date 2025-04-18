//
//  RendererState.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/11/25.
//

class RendererState {
    var triangleProps: [TriangleProps] = []
    var textureProps: [TextureProps?] = []
    var colorProps: [ColorProps] = []
    var tiles: [TileState] = [TileState](repeating: TileState(), count: 8)
    var zProps: [ZProps?] = []
    var fillRects: [FillRect] = []
    var currentTile: Int = 0
    var canRender = false
    var blockTexelsLoaded: UInt32 = 0

    var textureBuffer: [UInt8] = []
}
