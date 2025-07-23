//
//  SaveState.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/14/24.
//

import Foundation
import SwiftData

@Model
class SaveState : Snapshottable {
    var saveName: String
    var screenshot: Data
    var bookmark: Data
    @Attribute(.unique)
    var game: Game?

    @Transient
    var gbaGame: GBAGame? = nil
    @Transient
    var gbcGame: GBCGame? = nil

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
