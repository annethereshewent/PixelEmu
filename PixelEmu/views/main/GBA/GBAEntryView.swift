//
//  GBAEntryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/28/24.
//

import SwiftUI

struct GBAEntryView: View {
    @Binding var themeColor: Color
    let game: GBAGame
    let callback: () -> Void

    private let graphicsParser = GraphicsParser()

    var body: some View {
        VStack(spacing: 0) {
            Button {
                callback()
            } label: {
                if let albumArt = game.albumArt {
                    let uiImage = UIImage(data: albumArt)
                    Image(uiImage: uiImage!)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .scaledToFill()
                } else {
                    ZStack {
                        Image("Cartridge")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .background(themeColor)
                        VStack {
                            Text("GBA")
                                .font(.custom("Departure Mono", size: 14))
                        }
                        Spacer()
                    }
                }
            }
            Text(game.gameName.replacing(".gba", with: ""))
                .frame(width: 80, height: 80)
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("Departure Mono", size: 10))
        }
    }
}
