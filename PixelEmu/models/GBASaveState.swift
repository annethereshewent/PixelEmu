//
//  GBASaveState.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 12/6/24.
//

import Foundation
import SwiftData

@Model
class GBASaveState : Snapshottable {
    var saveName: String
    var screenshot: Data
    var bookmark: Data
    var gbaGame: GBAGame?

    @Transient
    var gbcGame: GBCGame? = nil
    @Transient
    var game: Game? = nil

    var timestamp: Int

    init(saveName: String, screenshot: [UInt8], bookmark: Data, timestamp: Int, game: GBAGame? = nil) {
        self.saveName = saveName
        self.screenshot = Data(screenshot)
        self.bookmark = bookmark
        self.timestamp = timestamp

        self.gbaGame = game
    }

    func compare(_ rhs: GBASaveState) -> Bool {
        return self.timestamp < rhs.timestamp
    }
}
