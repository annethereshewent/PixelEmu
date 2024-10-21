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
    @Binding var runningGame: Game?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var gameUrl: URL?
    
    @State private var isLoadStatesPresented = false
    @State private var selectedGame: Game?
   
    
    let game: Game
    
    let callback: () -> Void
    
    var body: some View {
        GameEntryView(game: game) {
            callback()
        }
        .contextMenu {
            Button("Load save state") {
                print("isLoadStatesPresented before change = \(isLoadStatesPresented)")
                isLoadStatesPresented = true
                print(isLoadStatesPresented)
                self.selectedGame = game
                print("setting game to \(self.selectedGame!.gameName)")
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
        .sheet(isPresented: $isLoadStatesPresented) {
            LoadStatesView(
                emulator: $emulator,
                selectedGame: $selectedGame,
                game: $runningGame,
                isPresented: $isLoadStatesPresented,
                romData: $romData,
                bios7Data: $bios7Data,
                bios9Data: $bios9Data,
                firmwareData: $firmwareData,
                path: $path,
                isRunning: $isRunning,
                workItem: $workItem,
                gameUrl: $gameUrl
            )
        }
    }
}
