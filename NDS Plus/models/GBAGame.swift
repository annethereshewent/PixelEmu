//
//  GBAGame.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/28/24.
//

import Foundation
import SwiftData
import UIKit

@Model
class GBAGame {
    @Attribute(.unique)
    var gameName: String
    var bookmark: Data
    var albumArt: Data? = nil
    var lastPlayed: Date

    @Relationship(deleteRule: .cascade, inverse: \GBASaveState.game)
    var saveStates: [GBASaveState]

    init(gameName: String, bookmark: Data, saveStates: [GBASaveState], lastPlayed: Date) {
        self.gameName = gameName
        self.bookmark = bookmark
        self.lastPlayed = lastPlayed
        self.saveStates = saveStates
    }

    static func storeGame(gameName: String, data: Data, url: URL) -> GBAGame? {
        // store bookmark for later use
        if url.startAccessingSecurityScopedResource() {
            if let bookmark = try? url.bookmarkData(options: []) {
                return GBAGame(gameName: gameName, bookmark: bookmark, saveStates: [], lastPlayed: Date.now)
            }
        }

        return nil
    }
}
