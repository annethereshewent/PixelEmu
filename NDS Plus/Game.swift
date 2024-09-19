//
//  Game.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/18/24.
//

import Foundation


class Game {
    let path: URL
    let contents: Data
    
    init(path: URL, contents: Data) {
        self.path = path
        self.contents = contents
    }
}
