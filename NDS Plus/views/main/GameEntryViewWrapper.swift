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
    @Binding var emulator: MobileEmulator?
    
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var path: NavigationPath
    
    @State private var isLoadStatesPresented = false
    @State private var selectedGame: Game?
    
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
                isLoadStatesPresented = true
                selectedGame = game
            }
        }
        .sheet(isPresented: $isLoadStatesPresented) {
            LoadStatesView(
                emulator: $emulator,
                game: $selectedGame,
                isPresented: $isLoadStatesPresented,
                romData: $romData,
                bios7Data: $bios7Data,
                bios9Data: $bios9Data,
                firmwareData: $firmwareData,
                path: $path
            )
        }
    }
}
