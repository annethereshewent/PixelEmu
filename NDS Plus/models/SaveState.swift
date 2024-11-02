//
//  SaveState.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import Foundation
import SwiftData

@Model
class SaveState {
    var saveName: String
    @Attribute(originalName: "screenshot")
    var deleteMe: [UInt8]
    var bookmark: Data
    @Attribute(.unique)
    var game: Game?
    
    var timestamp: Int
    
    init(saveName: String, screenshot: [UInt8], bookmark: Data, timestamp: Int, game: Game? = nil) {
        self.saveName = saveName
        self.deleteMe = screenshot
        self.bookmark = bookmark
        self.timestamp = timestamp
        
        self.game = game
    }
    
    func compare(_ rhs: SaveState) -> Bool {
        return self.timestamp < rhs.timestamp
    }
}
