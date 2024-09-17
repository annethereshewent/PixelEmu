//
//  GraphicsParser.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/16/24.
//

import Foundation
import CoreGraphics
import UIKit

class GraphicsParser {
    func fromBytes(bytes: [UInt8]) -> UIImage? {
        let width = 256
        let height = 192
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32

        var data = bytes // Copy to mutable []
        guard let providerRef = CGDataProvider(data: NSData(bytes: &data,
                                length: data.count * 4)
            )
            else { return nil }

        guard let cgim = CGImage(
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

        return UIImage(cgImage: cgim)
    }
}
