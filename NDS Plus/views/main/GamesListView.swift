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
    @Binding var themeColor: Color

    @State private var showResumeDialog = false
    @State private var resumeGame = false
    @State private var settingChanged = false
    
    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteAction: () -> Void = {}
    @State private var gameToDelete: Game?
    @State private var showGameError = false

    @State private var isLoadStatesPresented = false
    @State private var selectedGame: Game?
    @Query private var games: [Game]
    
    private var filteredGames: [Game] {
        switch filter {
        case .all:
            return games.sorted {
                $0.lastPlayed > $1.lastPlayed
            }
        case .recent:
            return games.filter { game in
                let today = Date.now
                let diff = today.timeIntervalSince1970 - game.lastPlayed.timeIntervalSince1970

                return diff <= Double(TWELVE_HOURS)
            }.sorted {
                $0.lastPlayed > $1.lastPlayed
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
            game.lastPlayed = Date.now
            path.append("GameView")
        } else if let game = self.game {
            game.lastPlayed = Date.now
            path.append("GameView")
        } else {
            showGameError = true
        }
    }

    private func updateLastPlayed() {
        if let game = game {
            game.lastPlayed = Date.now
        }
    }

    var body: some View {
        if games.count > 0 {
            ZStack {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(filteredGames) { game in
                            GameEntryViewWrapper(
                                showDeleteConfirmation: $showDeleteConfirmation,
                                deleteAction: $deleteAction,
                                gameToDelete: $gameToDelete,
                                isLoadStatesPresented: $isLoadStatesPresented,
                                selectedGame: $selectedGame,
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
                                                    updateLastPlayed()
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
                        settingChanged: $settingChanged,
                        themeColor: $themeColor
                    )
                } else if showDeleteConfirmation {
                    DeleteDialog(
                        showDialog: $showDeleteConfirmation,
                        deleteAction: $deleteAction,
                        themeColor: $themeColor,
                        deleteMessage: "Are you sure you want to remove this game from your library?"
                    )
                } else if showDeleteError {
                    AlertModal(
                        alertTitle: "Oops!",
                        text: "There was an error removing the game.",
                        showAlert: $showDeleteError,
                        themeColor: $themeColor
                    )
                } else if showGameError {
                    AlertModal(
                        alertTitle: "Oops!",
                        text: "There was an error loading the specified game.",
                        showAlert: $showGameError,
                        themeColor: $themeColor
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
                        context.delete(game)
                    } else {
                        showDeleteError = true
                    }
                }
            }
            .sheet(isPresented: $isLoadStatesPresented) {
                LoadStatesView(
                    emulator: $emulator,
                    selectedGame: $selectedGame,
                    game: $game,
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
        } else {
            Spacer()
            Spacer()
        }
    }
}

