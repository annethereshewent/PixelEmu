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
    
    var body: some View {
        HStack {
            if let image = GraphicsParser().fromBytes(bytes: game.gameIcon, width: 32, height: 32) {
                Image(uiImage: image)
            }
            Button(game.gameName.removingPercentEncoding!) {
                callback()
            }
        }
    }
}
