//
//  MetalView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/3/25.
//
import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    var rendererState: RendererState
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

        let renderer = Renderer(mtkView: mtkView, state: rendererState)
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
