//
//  SaveStateV2.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/02/24.
//

import Foundation
import SwiftData

struct Screenshot: Codable {
    var bytes: [UInt8]
}


// i have to create an additional model because SwiftData migrations are fucking awful and i've fought them
// every step of the way and this is just a hacky way to get it to finally work
@Model
class SaveStateV2 {
    var saveName: String
    var screenshot: Screenshot
    var bookmark: Data
    @Attribute(.unique)
    var game: Game?

    var timestamp: Int

    init(saveName: String, screenshot: [UInt8], bookmark: Data, timestamp: Int, game: Game? = nil) {
        self.saveName = saveName

        self.bookmark = bookmark
        self.timestamp = timestamp
        self.screenshot = Screenshot(bytes: screenshot)

        self.game = game
    }

    func compare(_ rhs: SaveStateV2) -> Bool {
        return self.timestamp < rhs.timestamp
    }
}
