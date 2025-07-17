//
//  SaveState.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/14/24.
//

import Foundation
import SwiftData

@Model
class SaveState {
    var saveName: String
    var screenshot: Data
    var bookmark: Data
    @Attribute(.unique)
    var game: Game?

    var timestamp: Int

    init(saveName: String, screenshot: [UInt8], bookmark: Data, timestamp: Int, game: Game? = nil) {
        self.saveName = saveName
        self.screenshot = Data(screenshot)
        self.bookmark = bookmark
        self.timestamp = timestamp

        self.game = game
    }

    func compare(_ rhs: SaveState) -> Bool {
        return self.timestamp < rhs.timestamp
    }
}
