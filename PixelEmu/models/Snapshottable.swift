//
//  Snapshottable.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/22/25.
//

import Foundation

protocol Snapshottable {
    var saveName: String { get set }
    var screenshot: Data { get set }
    var bookmark: Data { get set }

    var game: Game? { get set }
    var gbaGame: GBAGame? { get set }
    var gbcGame: GBCGame? { get set }

    var timestamp: Int { get set }
}
