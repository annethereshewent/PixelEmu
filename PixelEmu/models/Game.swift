//
//  Game.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/18/24.
//

import Foundation
import SwiftData
import UIKit

let ICON_WIDTH = 32
let ICON_HEIGHT = 32

// Note: Since the DS was the first emulator supported and the only one I had in mind,
// I called this model Game.  Which in hindsight would have been better
// if I had called it NDSGame. Now it's stuck, because migration with SwiftData
// is an incredibly huge pain, and the alternative is for users to lose all their
// save state data and libraries by deleting the app and reinstalling to make it
// work again.
@Model
class Game: Playable {
    @Attribute(.unique)
    var gameName: String
    var bookmark: Data
    var gameIcon: Data?
    @Relationship(deleteRule: .cascade, inverse: \SaveState.game)
    var saveStates: [SaveState]?
    @Attribute(originalName: "addedOn")
    var lastPlayed: Date

    var albumArt: Data? = nil

    @Transient
    var type: GameType = .nds
    @Transient
    var gbaSaveStates: [GBASaveState]? = nil
    @Transient
    var gbcSaveStates: [GBCSaveState]? = nil


    init(gameName: String, bookmark: Data, gameIcon: [UInt8], saveStates: [SaveState], lastPlayed: Date) {
        self.bookmark = bookmark
        self.gameName = gameName
        self.gameIcon = Data(gameIcon)
        self.lastPlayed = lastPlayed
        self.saveStates = saveStates
    }

    static func storeGame(gameName: String, data: Data, url: URL, isZip: Bool) -> (any Playable)? {
        // store bookmark for later use
        if isZip {
            if let bookmark = try? url.bookmarkData(options: []) {
                return Game(gameName: gameName, bookmark: bookmark, gameIcon: [], saveStates: [], lastPlayed: Date.now) as any Playable
            }
        }
        else {
            if url.startAccessingSecurityScopedResource() {
                if let bookmark = try? url.bookmarkData(options: []) {
                    return Game(gameName: gameName, bookmark: bookmark, gameIcon: [], saveStates: [], lastPlayed: Date.now) as any Playable
                }
            }
        }


        return nil
    }
}


