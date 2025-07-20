//
//  MetalView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/19/25.
//

import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    let fullscreenQuad: [TexturedVertex] = [
        TexturedVertex(position: [-1,  1], uv: [0, 0]), // top-left
        TexturedVertex(position: [ 1,  1], uv: [1, 0]), // top-right
        TexturedVertex(position: [-1, -1], uv: [0, 1]), // bottom-left
        TexturedVertex(position: [ 1, -1], uv: [1, 1])  // bottom-right
    ]
    var onViewCreated: (_ view: MTKView, _ device: MTLDevice) -> Void

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColorMake(0.2, 0.2, 0.4, 1.0) // dark blue-ish
        mtkView.colorPixelFormat = .rgba8Unorm
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = true

        let renderer = Renderer(mtkView: mtkView)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer // retain the renderer

        mtkView.depthStencilPixelFormat = .depth32Float

        onViewCreated(mtkView, renderer.device)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator {
        var renderer: Renderer?

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            view.drawableSize = size
        }
    }
}
