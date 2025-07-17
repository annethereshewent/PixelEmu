//
//  GBASaveEntry.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 12/5/24.
//

import Foundation

// This is a wrapper around Game so that it can be used in the Save Management view
// without altering the underlying game model
class GBASaveEntry: Equatable {
    static func == (lhs: GBASaveEntry, rhs: GBASaveEntry) -> Bool {
        lhs.game.gameName == rhs.game.gameName
    }

    let game: GBAGame

    init(game: GBAGame) {
        self.game = game
    }

    func copy() -> GBASaveEntry {
        return GBASaveEntry(game: game)
    }
}
