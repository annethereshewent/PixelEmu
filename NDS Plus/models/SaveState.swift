//
//  SaveState.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import Foundation
import SwiftData

@Model
class SaveState {
    let saveName: String
    let screenshot: [UInt8]
    let bookmark: Data
    @Attribute(.unique)
    var game: Game?
    
    init(saveName: String, screenshot: [UInt8], bookmark: Data, game: Game? = nil) {
        self.saveName = saveName
        self.screenshot = screenshot
        self.bookmark = bookmark
        
        self.game = game
    }
    
    func compare(_ rhs: SaveState) -> Bool {
        let saveNum1 = self.saveName.replacing("Save ", with: "")
        let saveNum2 = rhs.saveName.replacing("Save ", with: "")
        
        return Int(saveNum1)! < Int(saveNum2)!
    }
}
