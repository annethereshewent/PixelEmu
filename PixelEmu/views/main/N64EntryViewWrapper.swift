//
//  N64EntryViewWrapper.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//

import SwiftUI

struct N64EntryViewWrapper: View {
    @Binding var showDeleteConfirmation: Bool
    @Binding var deleteAction: () -> Void
    @Binding var gameToDelete: N64Game?
    @Binding var isLoadStatesPresented: Bool
    @Binding var selectedGame: N64Game?
    @Binding var themeColor: Color


    let game: N64Game

    let callback: () -> Void

    var body: some View {
        N64EntryView(themeColor: $themeColor, game: game) {
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
