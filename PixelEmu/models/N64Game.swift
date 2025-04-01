//
//  GBAGame.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/28/24.
//

import Foundation
import SwiftData
import UIKit

@Model
class N64Game {
    @Attribute(.unique)
    var gameName: String
    var bookmark: Data
    var albumArt: Data? = nil
    var lastPlayed: Date

    init(gameName: String, bookmark: Data, lastPlayed: Date) {
        self.gameName = gameName
        self.bookmark = bookmark
        self.lastPlayed = lastPlayed
    }

    static func storeGame(gameName: String, data: Data, url: URL) -> N64Game? {
        // store bookmark for later use
        if url.startAccessingSecurityScopedResource() {
            if let bookmark = try? url.bookmarkData(options: []) {
                return N64Game(gameName: gameName, bookmark: bookmark, lastPlayed: Date.now)
            }
        }

        return nil
    }
}
