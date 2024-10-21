//
//  GamesListView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import SwiftUI
import DSEmulatorMobile
import SwiftData

struct GamesListView: View {
    @Environment(\.modelContext) private var context
    
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var emulator: MobileEmulator?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    @Binding var game: Game?
    @Binding var filter: LibraryFilter
    
    @State private var showResumeDialog = false
    @State private var resumeGame = false
    @State private var settingChanged = false
    
    @State private var showDeleteConfirmation = false
    @State private var showDeleteSuccess = false
    @State private var deleteAction: () -> Void = {}
    @State private var gameToDelete: Game?
    
    @Query private var games: [Game]
    
    private var filteredGames: [Game] {
        switch filter {
        case .all:
            return games.sorted {
                $0.addedOn > $1.addedOn
            }
        case .recent:
            return games.filter { game in
                let today = Date.now
                let diff = today.timeIntervalSince1970 - game.addedOn.timeIntervalSince1970
                
                return diff <= Double(TWENTYFOUR_HOURS)
            }.sorted {
                $0.addedOn > $1.addedOn
            }
        }
    }
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    private func startNewGame(_ game: Game? = nil) {
        emulator = nil
        workItem?.cancel()
        isRunning = false
        
        workItem = nil
        
        if let game = game {
            self.game = game
        }
        
        path.append("GameView")
    }
    
    var body: some View {
        if games.count > 0 {
            ZStack {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(filteredGames) { game in
                            GameEntryViewWrapper(
                                showDeleteConfirmation: $showDeleteConfirmation,
                                showDeleteSuccess: $showDeleteSuccess,
                                deleteAction: $deleteAction,
                                gameToDelete: $gameToDelete,
                                game: game
                            ) {
                                // refresh the url's bookmark
                                var isStale = false
                                if let url = try? URL(
                                    resolvingBookmarkData: game.bookmark,
                                    options: [.withoutUI],
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale
                                ) {
                                    if url.startAccessingSecurityScopedResource() {
                                        gameUrl = url
                                        defer {
                                            url.stopAccessingSecurityScopedResource()
                                        }
                                        if let data = try? Data(contentsOf: url) {
                                            romData = data
                                    
                                            if bios7Data != nil &&
                                                bios9Data != nil
                                            {
                                                if self.game != nil && self.game! == game {
                                                    showResumeDialog = true
                                                } else {
                                                    startNewGame(game)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if showResumeDialog {
                    ResumeGameDialog(
                        showDialog: $showResumeDialog,
                        resumeGame: $resumeGame,
                        settingChanged: $settingChanged
                    )
                } else if showDeleteConfirmation {
                    DeleteDialog(
                        showDialog: $showDeleteConfirmation,
                        deleteAction: $deleteAction,
                        deleteMessage: "Are you sure you want to remove this game from your library?"
                    )
                } else if showDeleteSuccess {
                    AlertModal(
                        text: "Successfully removed game from library.",
                        showAlert: $showDeleteSuccess
                    )
                }
            }
            .onChange(of: settingChanged) {
                if resumeGame {
                    emulator?.setPause(false)
                    path.append("GameView")
                } else {
                    startNewGame()
                }
            }
            .onChange(of: gameToDelete) {
                deleteAction = {
                    if let game = gameToDelete {
                        print("deleting the game!")
                        context.delete(game)
                        showDeleteSuccess = true
                    }
                }
            }
        } else {
            Spacer()
            Spacer()
        }
    }
}

