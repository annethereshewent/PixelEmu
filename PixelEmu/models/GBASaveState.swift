//
//  GBASaveState.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 12/6/24.
//

import Foundation
import SwiftData

@Model
class GBASaveState {
    var saveName: String
    var screenshot: Data
    var bookmark: Data
    @Attribute(.unique)
    var game: GBAGame?

    var timestamp: Int

    init(saveName: String, screenshot: [UInt8], bookmark: Data, timestamp: Int, game: GBAGame? = nil) {
        self.saveName = saveName
        self.screenshot = Data(screenshot)
        self.bookmark = bookmark
        self.timestamp = timestamp

        self.game = game
    }

    func compare(_ rhs: GBASaveState) -> Bool {
        return self.timestamp < rhs.timestamp
    }
}
