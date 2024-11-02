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
    var gameName: String
    var bookmark: Data
    var gameIcon: [UInt8]
    @Relationship(deleteRule: .cascade, inverse: \SaveState.game)
    var saveStates: [SaveState]
    @Relationship(deleteRule: .cascade, inverse: \SaveStateV2.game)
    var saveStatesV2: [SaveStateV2]
    @Attribute(originalName: "addedOn")
    var lastPlayed: Date


    init(gameName: String, bookmark: Data, gameIcon: [UInt8], saveStates: [SaveState], saveStatesV2: [SaveStateV2], lastPlayed: Date) {
        self.bookmark = bookmark
        self.gameName = gameName
        self.gameIcon = gameIcon
        self.saveStates = saveStates
        self.saveStatesV2 = saveStatesV2
        self.lastPlayed = lastPlayed
    }

    static func storeGame(gameName: String, data: Data, url: URL, iconPtr: UnsafePointer<UInt8>) -> Game? {
        let buffer = UnsafeBufferPointer(start: iconPtr, count: ICON_WIDTH * ICON_HEIGHT * 4)

        let pixelsArr = Array(buffer)

        // store bookmark for later use
        if url.startAccessingSecurityScopedResource() {
            if let bookmark = try? url.bookmarkData(options: []) {
                return Game(gameName: gameName, bookmark: bookmark, gameIcon: pixelsArr, saveStates: [], saveStatesV2: [], lastPlayed: Date.now)
            }
        }

        return nil
    }

    static func migrateSaveStates(games: [Game]) {
        for game in games {
            if game.saveStatesV2.count == 0  && game.saveStates.count > 0 {
                for state in game.saveStates {
                    // saveName: String, screenshot: [UInt8], bookmark: Data, timestamp: Int, game: Game? = ni
                    game.saveStatesV2.append(SaveStateV2(
                        saveName: state.saveName,
                        screenshot: state.deleteMe,
                        bookmark: state.bookmark,
                        timestamp: state.timestamp
                    ))
                }
                game.saveStates = []
            }
        }
    }
}

