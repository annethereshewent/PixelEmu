//
//  GameEntryViewWrapper.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/20/24.
//

import SwiftUI

struct GameEntryViewWrapper: View {
    @Binding var showDeleteConfirmation: Bool
    @Binding var showDeleteSuccess: Bool
    @Binding var deleteAction: () -> Void
    @Binding var gameToDelete: Game?
    
    let game: Game
    
    let callback: () -> Void
    
    var body: some View {
        GameEntryView(game: game) {
            callback()
        }
        .contextMenu {
            Button("Remove game from library") {
                showDeleteSuccess = false
                showDeleteConfirmation = true
                gameToDelete = game
            }
            Button("Load save state") {
                
            }
        }

    }
}
