//
//  GBCGame.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/18/25.
//

import Foundation
import SwiftData

@Model
class GBCGame: Playable {
    init(gameName: String, bookmark: Data, lastPlayed: Date) {
        self.gameName = gameName
        self.bookmark = bookmark
        self.lastPlayed = lastPlayed
    }

    @Attribute(.unique)
    var gameName: String
    var bookmark: Data
    var albumArt: Data? = nil
    var lastPlayed: Date

    @Transient
    var gameIcon: Data? = nil

    @Transient
    var type: GameType = .gbc

    @Transient
    var gbaSaveStates: [GBASaveState]? = nil

    @Transient
    var saveStates: [SaveState]? = nil

    static func storeGame(gameName: String, data: Data, url: URL, isZip: Bool = false) -> (any Playable)? {
        // store bookmark for later use
        if isZip {
            let bookmark = try! url.bookmarkData(options: [])
            return GBCGame(gameName: gameName, bookmark: bookmark, lastPlayed: Date.now) as any Playable
        }

        if url.startAccessingSecurityScopedResource() {
            let bookmark = try! url.bookmarkData(options: [])
            return GBCGame(gameName: gameName, bookmark: bookmark, lastPlayed: Date.now) as any Playable
        }

        return nil
    }
}
