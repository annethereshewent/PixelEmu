//
//  GameEntry.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/22/24.
//

import Foundation

class GameEntry: Decodable {
    var gameCode: UInt32
    var romSize: UInt
    var saveType: String
    var ramCapacity: UInt
    
    static func decodeGameDb() -> [GameEntry]? {
        guard let path = Bundle.main.path(forResource: "game_db", ofType: "json") else { return nil }
        
        let url = URL(fileURLWithPath: path)
        
        var gameEntries: [GameEntry]? = nil
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            gameEntries = try decoder.decode([GameEntry].self, from: data)
        } catch {
            print(error)
        }
        
        return gameEntries
    }
}
