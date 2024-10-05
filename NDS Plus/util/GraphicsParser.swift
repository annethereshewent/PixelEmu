//
//  GraphicsParser.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/16/24.
//

import Foundation
import CoreGraphics
import UIKit

let SCREEN_WIDTH = 256
let SCREEN_HEIGHT = 192
let SCREEN_RATIO: Float = 1.36

class GraphicsParser {
    func fromPointer(ptr: UnsafePointer<UInt8>) -> CGImage? {
        let buffer = UnsafeBufferPointer(start: ptr, count: SCREEN_HEIGHT * SCREEN_WIDTH * 4)
        
        let pixelsArr = Array(buffer)
        
        return fromBytes(bytes: pixelsArr, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
    }
    
    func fromBytes(bytes: [UInt8], width: Int, height: Int) -> CGImage? {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32

        var data = bytes // Copy to mutable []
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data,
                                length: data.count)
            )
            else { return nil }

        guard let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerPixel,
                bytesPerRow: width * 4,
                space: rgbColorSpace,
                bitmapInfo: bitmapInfo,
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
            else { return nil }
        
        return image
    }
}
