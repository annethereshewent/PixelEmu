//
//  Game.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/18/24.
//

import Foundation
import SwiftData
import UIKit

let ICON_WIDTH = 32
let ICON_HEIGHT = 32

@Model
class Game {
    @Attribute(.unique)
    let gameName: String
    let bookmark: Data
    let gameIcon: [UInt8]
    
    init(gameName: String, bookmark: Data, gameIcon: [UInt8]) {
        self.bookmark = bookmark
        self.gameName = gameName
        self.gameIcon = gameIcon
    }
    
    static func storeGame(gameName: String, data: Data, url: URL, iconPtr: UnsafePointer<UInt8>) -> Game? {
        let buffer = UnsafeBufferPointer(start: iconPtr, count: ICON_WIDTH * ICON_HEIGHT * 4)
        
        let pixelsArr = Array(buffer)
        
        // store bookmark for later use
        if url.startAccessingSecurityScopedResource() {
            if let bookmark = try? url.bookmarkData(options: []) {
                return Game(gameName: gameName, bookmark: bookmark, gameIcon: pixelsArr)
            }
        }
        
        
        return nil
    }
}
