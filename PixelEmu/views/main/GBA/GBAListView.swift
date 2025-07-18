//
//  GBAListView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/28/24.
//

import SwiftUI
import GBAEmulatorMobile
import SwiftData

struct GBAListView: View {
    @Environment(\.modelContext) private var context
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteAction: () -> Void = {}
    @State private var gameToDelete: (any Playable)?

    @State private var showResumeDialog = false
    @State private var settingChanged = false
    @State private var isLoadStatesPresented = false
    @State private var selectedGame: (any Playable)?
    @State private var selectedGbaGame: GBAGame?
    @State private var gbaGame: GBAGame?
    @State private var resumeGame: Bool = false

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
    @Binding var isPaused: Bool


    var filteredGames: [GBAGame]

    private func startNewGame(_ game: GBAGame? = nil) {
        emulator = nil
        workItem?.cancel()
        isRunning = false

        isPaused = false

        workItem = nil

        if let game = game {
            self.game = game
            game.lastPlayed = Date.now
            path.append("GBAGameView")
        } else if let game = self.game as! GBAGame? {
            game.lastPlayed = Date.now
            path.append("GBAGameView")
        } else {
            showGameError = true
        }
    }

    private func updateLastPlayed() {
        if let game = game as! GBAGame? {
            game.lastPlayed = Date.now
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
                            var isStale = false
                            do {
                                let url = try URL(
                                    resolvingBookmarkData: game.bookmark,
                                    options: [.withoutUI],
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale
                                )
                                if url.startAccessingSecurityScopedResource() {
                                    defer {
                                        url.stopAccessingSecurityScopedResource()
                                    }


                                    let data = try Data(contentsOf: url)

                                    romData = data
                                    gameUrl = url

                                    let gbaGame = self.game as! GBAGame?
                                    if gbaGame != nil && gbaGame! == game {
                                        updateLastPlayed()
                                        showResumeDialog = true
                                    } else {
                                        startNewGame(game)
                                    }
                                }
                            } catch {
                                print(error)
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
        .onChange(of: game?.gameName) {
            gbaGame = game as! GBAGame?
        }
        .onChange(of: selectedGame?.gameName) {
            selectedGbaGame = selectedGame as! GBAGame?
        }
        .onChange(of: settingChanged) {
            if resumeGame {
                emulator?.setPaused(false)
                path.append("GBAGameView")
            } else {
                startNewGame()
            }
        }
        .onChange(of: gameToDelete?.gameName) {
            deleteAction = {
                if let game = gameToDelete {
                    context.delete(game as! GBAGame)
                } else {
                    showDeleteError = true
                }
            }
        }
    }
}

