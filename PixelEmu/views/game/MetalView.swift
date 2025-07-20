//
//  MetalView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/19/25.
//

class RenderingData {
    var framebuffer: [UInt8]? = nil
}

import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    var renderingData: RenderingData
    var width: Int
    var height: Int
    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }

        print("initializing MetalView")

        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.clearColor = MTLClearColorMake(0.2, 0.2, 0.4, 1.0) // dark blue-ish
        mtkView.colorPixelFormat = .rgba8Unorm

        print("render width \(width) height \(height)")

        let renderer = Renderer(mtkView: mtkView, renderingData: renderingData, width: width, height: height)
        mtkView.delegate = renderer
        context.coordinator.renderer = renderer // retain the renderer

        mtkView.depthStencilPixelFormat = .depth32Float

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {

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
