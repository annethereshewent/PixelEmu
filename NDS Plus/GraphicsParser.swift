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

class GraphicsParser {
    func fromPointer(ptr: UnsafePointer<UInt8>) -> UIImage? {
        let buffer = UnsafeBufferPointer(start: ptr, count: SCREEN_HEIGHT * SCREEN_WIDTH * 4)
        
        let pixelsArr = Array(buffer)
        
        return fromBytes(bytes: pixelsArr)
    }
    
    private func fromBytes(bytes: [UInt8]) -> UIImage? {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32

        var data = bytes // Copy to mutable []
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data,
                                length: data.count)
            )
            else { return nil }

        guard let cgim = CGImage(
                width: SCREEN_WIDTH,
                height: SCREEN_HEIGHT,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerPixel,
                bytesPerRow: SCREEN_WIDTH * 4,
                space: rgbColorSpace,
                bitmapInfo: bitmapInfo,
                provider: providerRef,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
            )
            else { return nil }

        return UIImage(cgImage: cgim)
    }
}
