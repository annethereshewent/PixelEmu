//
//  GBAEntryViewWrapper.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/28/24.
//

import SwiftUI
import DSEmulatorMobile

struct GBAEntryViewWrapper: View {
    @Binding var showDeleteConfirmation: Bool
    @Binding var deleteAction: () -> Void
    @Binding var gameToDelete: GBAGame?
    @Binding var isLoadStatesPresented: Bool
    @Binding var selectedGame: GBAGame?
    @Binding var themeColor: Color


    let game: GBAGame

    let callback: () -> Void

    var body: some View {
        GBAEntryView(themeColor: $themeColor, game: game) {
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
