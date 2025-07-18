//
//  GameEntryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/24/24.
//

import SwiftUI

struct GameEntryView: View {
    let game: any Playable
    let callback: () -> Void

    private let graphicsParser = GraphicsParser()

    func getConsoleTitle(type: GameType) -> String {
        switch type {
        case .nds: return "NDS"
        case .gba: return "GBA"
        case .gbc: return "GBC"
        }
    }

    func removeExtension(game: any Playable) -> String {
        switch game.type {
        case .nds:
            return game.gameName.replacing(".nds", with: "")
        case .gba:
            if game.gameName.hasSuffix(".gba") {
                return game.gameName.replacing(".nds", with: "")
            } else if game.gameName.hasSuffix(".GBA") {
                return game.gameName.replacing(".GBA", with: "")
            }
        case .gbc:
            if game.gameName.hasSuffix(".gb") {
                return game.gameName.replacing(".gb", with: "")
            } else if game.gameName.hasSuffix(".gbc") {
                return game.gameName.replacing(".gbc", with: "")
            }
        }

        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                callback()
            } label: {
                if let artwork = game.albumArt {
                    let uiImage = UIImage(data: artwork)
                    Image(uiImage: uiImage!)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .scaledToFill()
                } else if let gameIcon = game.gameIcon {
                    ZStack {
                        Image("Cartridge")
                            .resizable()
                            .frame(width: 80, height: 80)
                        VStack {
                            if let image = graphicsParser.fromBytes(bytes: Array(gameIcon), width: 32, height: 32) {
                                let uiImage = UIImage(cgImage: image)
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 64, height: 64)
                            } else {
                                Text(getConsoleTitle(type: game.type))
                            }
                        }
                        Spacer()
                    }
                } else {
                    
                }
            }
            Text(removeExtension(game: game))
                .frame(width: 80, height: 80)
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("Departure Mono", size: 10))
        }
    }
}
