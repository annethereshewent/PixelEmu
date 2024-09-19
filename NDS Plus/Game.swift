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
    let path: URL
    let gameName: String
    
    init(path: URL, gameName: String) {
        print("Storing \(gameName)")
        self.path = path
        self.gameName = gameName
    }
}
