//
//  SaveEntry.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/24/24.
//

import Foundation

class SaveEntry: Equatable {
    static func == (lhs: SaveEntry, rhs: SaveEntry) -> Bool {
        lhs.game.gameName == rhs.game.gameName
    }
    
    let game: Game
    
    init(game: Game) {
        self.game = game
    }
    
    
}
