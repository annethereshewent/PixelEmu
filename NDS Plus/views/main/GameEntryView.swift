//
//  GameEntryView.swift
//  NDS Plus
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
            ZStack {
                Image("Cartridge")
                    .resizable()
                    .frame(width: 80, height: 80)
                VStack {
                    if let image = graphicsParser.fromBytes(bytes: game.gameIcon, width: 32, height: 32) {
                        let uiImage = UIImage(cgImage: image)
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 64, height: 64)
                    }
                }
                Spacer()
            }
            Text(game.gameName.replacing(".nds", with: ""))
                .frame(width: 80, height: 80)
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("Departure Mono", size: 10))
        }
    }
}
