//
//  N64EntryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//

import SwiftUI

struct N64EntryView: View {
    @Binding var themeColor: Color
    let game: N64Game
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
                            Text("N64")
                                .font(.custom("Departure Mono", size: 14))
                        }
                        Spacer()
                    }
                }
            }
            Text(game.gameName.replacing(".n64", with: "").replacing(".z64", with: ""))
                .frame(width: 80, height: 80)
                .fixedSize(horizontal: false, vertical: true)
                .font(.custom("Departure Mono", size: 10))
        }
    }
}
