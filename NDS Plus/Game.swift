//
//  Game.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/18/24.
//

import Foundation
import SwiftData

@Model
class Game {
    @Attribute(.unique)
    let gameName: String
    let bookmark: Data
    
    init(gameName: String, bookmark: Data) {
        self.bookmark = bookmark
        self.gameName = gameName
    }
    
    static func storeGame(data: Data, url: URL) -> Game? {
        let gameName = String(url
            .relativeString
            .split(separator: "/")
            .last
            .unsafelyUnwrapped
        )
            .removingPercentEncoding
            .unsafelyUnwrapped
        
        // store bookmark for later use
        if let bookmark = try? url.bookmarkData(options: []) {
            return Game(gameName: gameName, bookmark: bookmark)
        }
        
        return nil
    }
}
