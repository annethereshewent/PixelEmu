//
//  DSListView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/17/25.
//

import SwiftUI

import DSEmulatorMobile

struct DSListView: View {
    @Environment(\.modelContext) private var context
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteAction: () -> Void = {}
    @State private var gameToDelete: (any Playable)?

    @State private var showResumeDialog = false
    @State private var resumeGame = false
    @State private var settingChanged = false
    @State private var isLoadStatesPresented = false
    @State private var selectedGame: (any Playable)? = nil
    @State private var dsGame: Game? = nil
    @State private var selectedDsGame: Game? = nil

    @Binding var showGameError: Bool
    @Binding var gameUrl: URL?
    @Binding var themeColor: Color
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var game: (any Playable)?
    @Binding var workItem: DispatchWorkItem?
    @Binding var isRunning: Bool
    @Binding var path: NavigationPath

    var filteredGames: [Game]

    private func updateLastPlayed() {
        if let game = game as! Optional<Game> {
            game.lastPlayed = Date.now
        }
    }

    private func startNewGame(_ game: Game? = nil) {
        emulator = nil
        workItem?.cancel()
        isRunning = false

        workItem = nil

        if let game = game {
            self.game = game
            game.lastPlayed = Date.now
            path.append("GameView")
        } else if let game = self.game as! Game? {
            game.lastPlayed = Date.now
            path.append("GameView")
        } else {
            showGameError = true
        }
    }

    var body: some View {
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
                            themeColor: $themeColor,
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
                                            let dsGame = self.game as! Game?
                                            if dsGame != nil && dsGame! == game {
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
            .onChange(of: settingChanged) {
                if resumeGame {
                    emulator?.setPaused(false)
                    path.append("GameView")
                } else {
                    startNewGame()
                }
            }
            .onChange(of: game?.gameName) {
                dsGame = game as! Game?
            }
            .onChange(of: selectedGame?.gameName) {
                selectedDsGame = selectedGame as! Game?
            }
            .onChange(of: gameToDelete?.gameName) {
                deleteAction = {
                    if let game = gameToDelete {
                        context.delete(game as! Game)
                    } else {
                        showDeleteError = true
                    }
                }
            }
            .onAppear() {
                dsGame = game as! Game?
            }
            .sheet(isPresented: $isLoadStatesPresented) {
                LoadStatesView(
                    emulator: $emulator,
                    selectedGame: $selectedDsGame,
                    game: $dsGame,
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
    }
}
