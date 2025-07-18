//
//  GameEntryViewWrapper.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/20/24.
//

import SwiftUI

struct GameEntryViewWrapper: View {
    @Binding var showDeleteConfirmation: Bool
    @Binding var deleteAction: () -> Void
    @Binding var gameToDelete: (any Playable)?
    @Binding var isLoadStatesPresented: Bool
    @Binding var selectedGame: (any Playable)?


    let game: any Playable

    let callback: () -> Void

    var body: some View {
        GameEntryView(game: game) {
            callback()
        }
        .contextMenu {
            Button("Load save state") {
                isLoadStatesPresented = true
                self.selectedGame = game
            }
            Button (role: .destructive){
                showDeleteConfirmation = true
                gameToDelete = game
            } label: {
                HStack {
                    Text("Remove game from library")
                    Image(systemName: "trash")
                }
            }

        }
    }
}
