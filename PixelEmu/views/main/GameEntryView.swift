//
//  GameEntryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/24/24.
//

import SwiftUI

struct GameEntryView: View {
    let game: Game
    let callback: () -> Void

    private let graphicsParser = GraphicsParser()

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
                } else {
                    ZStack {
                        Image("Cartridge")
                            .resizable()
                            .frame(width: 80, height: 80)
                        VStack {
                            if let image = graphicsParser.fromBytes(bytes: Array(game.gameIcon), width: 32, height: 32) {
                                let uiImage = UIImage(cgImage: image)
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 64, height: 64)
                            } else {
                                Text("NDS")
                            }
                        }
                        Spacer()
                    }
                }
            }
            Text(game.gameName.replacing(".nds", with: ""))
                .frame(width: 80, height: 80)
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("Departure Mono", size: 10))
        }
    }
}
