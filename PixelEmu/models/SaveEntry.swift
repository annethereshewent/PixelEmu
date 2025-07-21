//
//  SaveEntry.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/24/24.
//

import Foundation

// This is a wrapper around Game so that it can be used in the Save Management view
// without altering the underlying game model
class SaveEntry: Equatable {
    static func == (lhs: SaveEntry, rhs: SaveEntry) -> Bool {
        lhs.game.gameName == rhs.game.gameName
    }

    let game: any Playable

    init(game: any Playable) {
        self.game = game
    }

    func copy() -> SaveEntry {
        return SaveEntry(game: game)
    }
}
