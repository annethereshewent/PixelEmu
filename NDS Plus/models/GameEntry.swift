//
//  GameEntry.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import Foundation

class GameEntry: Decodable {
    var gameCode: UInt32
    var romSize: UInt
    var saveType: String
    var ramCapacity: UInt
}
