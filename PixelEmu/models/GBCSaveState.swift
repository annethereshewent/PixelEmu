//
//  GBCSaveState.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/22/25.
//

import Foundation
import SwiftData

@Model
class GBCSaveState : Snapshottable {
    var saveName: String
    var screenshot: Data
    var bookmark: Data
    @Attribute(.unique)
    var gbcGame: GBCGame?

    @Transient
    var gbaGame: GBAGame? = nil
    @Transient
    var game: Game? = nil

    var timestamp: Int

    init(saveName: String, screenshot: [UInt8], bookmark: Data, timestamp: Int, game: GBCGame? = nil) {
        self.saveName = saveName
        self.screenshot = Data(screenshot)
        self.bookmark = bookmark
        self.timestamp = timestamp

        self.gbcGame = game
    }

    func compare(_ rhs: GBCSaveState) -> Bool {
        return self.timestamp < rhs.timestamp
    }
}
