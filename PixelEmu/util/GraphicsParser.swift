//
//  GraphicsParser.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/16/24.
//

import Foundation
import CoreGraphics
import UIKit

let SCREEN_WIDTH = 256
let SCREEN_HEIGHT = 192

let GBA_SCREEN_WIDTH = 240
let GBA_SCREEN_HEIGHT = 160

let GBC_SCREEN_WIDTH = 160
let GBC_SCREEN_HEIGHT = 144

let SCREEN_RATIO: Float = 1.4
let FULLSCREEN_RATIO: Float = 1.6
let LANDSCAPE_RATIO: Float = 1.20
let LANDSCAPE_FULLSCREEN_RATIO: Float = 1.70

let GBA_SCREEN_RATIO: Float = 1.6
let GBA_FULLSCREEN_RATIO: Float = 2.0

let GBA_LANDSCAPE_RATIO: Float = 1.3
let GBA_LANDSCAPE_FULLSCREEN_RATIO: Float = 2.25

class GraphicsParser {
    func fromPointer(ptr: UnsafePointer<UInt8>) -> CGImage? {
        let buffer = UnsafeBufferPointer(start: ptr, count: SCREEN_HEIGHT * SCREEN_WIDTH * 4)

        let pixelsArr = Array(buffer)

        return fromBytes(bytes: pixelsArr, width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
    }

    func fromGBAPointer(ptr: UnsafePointer<UInt8>) -> CGImage? {
        let buffer = UnsafeBufferPointer(start: ptr, count: GBA_SCREEN_HEIGHT * GBA_SCREEN_WIDTH * 4)

        let pixelsArr = Array(buffer)

        return fromBytes(bytes: pixelsArr, width: GBA_SCREEN_WIDTH, height: GBA_SCREEN_HEIGHT)
    }

    func fromGBCPointer(ptr: UnsafePointer<UInt8>) -> CGImage? {
        let buffer = UnsafeBufferPointer(start: ptr, count: GBC_SCREEN_HEIGHT * GBC_SCREEN_WIDTH * 3)

        let pixelsArr = Array(buffer)

        return fromBytes(bytes: convertArr(pixelsArr), width: GBC_SCREEN_WIDTH, height: GBC_SCREEN_HEIGHT)
    }

    func convertArr(_ arr: [UInt8]) -> [UInt8] {
        var newArr: [UInt8] = Array(repeating: 0, count: GBC_SCREEN_WIDTH * GBC_SCREEN_HEIGHT * 4)

        for y in 0..<GBC_SCREEN_HEIGHT {
            for x in 0..<GBC_SCREEN_WIDTH {
                let newIndex = (x + y * GBC_SCREEN_WIDTH) * 4
                let index = (x + y * GBC_SCREEN_WIDTH) * 3

                newArr[newIndex] = arr[index]
                newArr[newIndex + 1] = arr[index + 1]
                newArr[newIndex + 2] = arr[index + 2]
                newArr[newIndex + 3] = 0xff
            }
        }

        return newArr
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
