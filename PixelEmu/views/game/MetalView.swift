//
//  MetalView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/19/25.
//

class RenderingData {
    var framebuffer: UnsafePointer<UInt8>? = nil
    var shouldStep = true
    var mtkView: MTKView? = nil
}

import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    var renderingData: RenderingData
    func makeUIView(context: Context) -> MTKView {
        print("im being created!")
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColorMake(0.2, 0.2, 0.4, 1.0) // dark blue-ish
        mtkView.colorPixelFormat = .rgba8Unorm

        let renderer = Renderer(mtkView: mtkView, renderingData: renderingData)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer // retain the renderer

        mtkView.depthStencilPixelFormat = .depth32Float

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        print("updating UI view!!")
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
