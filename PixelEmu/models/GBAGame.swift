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
class GBAGame: Playable {
    @Attribute(.unique)
    var gameName: String
    var bookmark: Data
    var albumArt: Data? = nil
    var lastPlayed: Date

    @Transient
    var gameIcon: Data? = nil

    @Transient
    var type: GameType = .gba

    @Relationship(deleteRule: .cascade, inverse: \GBASaveState.gbaGame)
    var gbaSaveStates: [GBASaveState]?

    @Transient
    var saveStates: [SaveState]? = nil

    init(gameName: String, bookmark: Data, saveStates: [GBASaveState], lastPlayed: Date) {
        self.gameName = gameName
        self.bookmark = bookmark
        self.lastPlayed = lastPlayed
        self.gbaSaveStates = saveStates
    }

    static func storeGame(gameName: String, data: Data, url: URL, isZip: Bool) -> (any Playable)? {
        // store bookmark for later use
        if isZip {
            if let bookmark = try? url.bookmarkData(options: []) {
                return GBAGame(gameName: gameName, bookmark: bookmark, saveStates: [], lastPlayed: Date.now) as any Playable
            }
        }
        else {
            if url.startAccessingSecurityScopedResource() {
                if let bookmark = try? url.bookmarkData(options: []) {
                    return GBAGame(gameName: gameName, bookmark: bookmark, saveStates: [], lastPlayed: Date.now) as any Playable
                }
            }
        }



        return nil
    }
}
