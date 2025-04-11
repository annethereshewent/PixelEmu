//
//  MetalView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/3/25.
//
import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    @Binding var enqueuedWords: [[UInt32]]
    var onViewCreated: (_ view: MTKView) -> Void

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColorMake(0.2, 0.2, 0.4, 1.0) // dark blue-ish
        mtkView.colorPixelFormat = .rgba8Unorm
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = true

        let renderer = Renderer(mtkView: mtkView, enqueuedWords: enqueuedWords)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer // retain the renderer

        onViewCreated(mtkView)

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.enqueuedWords = enqueuedWords
        DispatchQueue.main.async {
            enqueuedWords = []
        }
    }

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
