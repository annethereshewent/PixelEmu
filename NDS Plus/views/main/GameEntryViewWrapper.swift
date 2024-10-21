//
//  GameEntryViewWrapper.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/20/24.
//

import SwiftUI
import DSEmulatorMobile

struct GameEntryViewWrapper: View {
    @Binding var showDeleteConfirmation: Bool
    @Binding var showDeleteSuccess: Bool
    @Binding var deleteAction: () -> Void
    @Binding var gameToDelete: Game?
    
    @Binding var isLoadStatesPresented: Bool
    @Binding var selectedGame: Game?
   
    
    let game: Game
    
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
                showDeleteSuccess = false
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
