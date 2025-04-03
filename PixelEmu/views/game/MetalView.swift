//
//  MetalView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/3/25.
//

import UIKit
import Metal
import QuartzCore

class MetalView: UIView {
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }

    var metalLayer: CAMetalLayer {
        return self.layer as! CAMetalLayer
    }
}
