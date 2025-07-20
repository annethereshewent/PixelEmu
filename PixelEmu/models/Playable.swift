//
//  Playable.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/16/25.
//
import Foundation

enum GameType {
    case nds
    case gba
    case gbc

    func getConsoleName() -> String {
        switch self {
        case .gba: return "GBA"
        case .nds: return "NDS"
        case .gbc: return "GBC"
        }
    }
}

protocol Playable: Identifiable {
    var gameName: String { get set }
    var bookmark: Data { get set }
    var albumArt: Data? { get set }
    var lastPlayed: Date { get set }
    var gameIcon: Data? { get set }

    var saveStates: [SaveState]? { get set }
    var gbaSaveStates: [GBASaveState]? { get set }

    var type: GameType { get }

    static func storeGame(gameName: String, data: Data, url: URL, iconPtr: UnsafePointer<UInt8>?, isZip: Bool) -> (any Playable)?
}


